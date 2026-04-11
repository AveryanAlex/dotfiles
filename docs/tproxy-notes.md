# mihomo + kernel TPROXY notes

Field notes from building + debugging `modules/tproxy.nix`, `modules/mihomo.nix`,
and `roles/core/mihomo.nix`. Captures things that cost hours to discover so
future-you doesn't re-pay the tax.

## Architecture at a glance

```
                     userspace
                        |
               ┌────────▼────────┐
               │      mihomo     │  (services.mihomo from nixpkgs, DynamicUser)
               │  transparent    │  Listens dual-stack :18298 (tproxy)
               │    socket       │  127.0.0.1:8080 (http), :1080 (socks),
               └────────▲────────┘  0.0.0.0:9090 (REST API + metacubexd UI)
                        |
                        |  1) tproxy `assign_sock`
                        |  2) routing: mark → table <N> → local default dev lo
                        |  3) `ip_local_deliver` → socket
                        |
    ┌───────────────────┼───────────────────┐
    │           kernel (netfilter)          │
    │                                       │
    │  inet ttproxy table                   │
    │    divert (prerouting, mangle-5)      │  existing transparent sockets
    │    prerouting (mangle, -150)          │  main dispatcher
    │      bypass4/bypass6 sets             │  RFC1918 + multicast + link-local
    │      fib daddr type local return      │  host-local nginx etc.
    │      iifname @forward → redirect_fwd  │  container traffic
    │      iifname lo      → redirect_out   │  re-injected local output
    │    output  (route, mangle)            │  marks local egress, type=route
    │                                       │  reruns routing → fwmark → lo
    │    redirect_forward / redirect_output │  the actual `tproxy ip to :port
    │                                       │   meta mark set <mark>` rules
    │                                       │
    │  inet nixos-fw rpfilter-allow         │
    │    meta mark <mark> accept            │  rpfilter bypass for our traffic
    └───────────────────────────────────────┘
```

## The two-mark system

| Option | Default | Who sets it | Role |
|---|---|---|---|
| `networking.tproxy.mark` | `18298` (`0x477a`) | **our** nft rules only | Policy-routing mark. Kernel sees it in the post-prerouting route lookup, matches `ip rule fwmark <mark> table <table>`, looks up `local default dev lo` → local delivery. |
| `networking.tproxy.backendMark` | `18299` (`0x477b`) | **mihomo** via `routing-mark` (SO_MARK) | Loop-prevention mark. mihomo tags its own upstream sockets; the output chain `meta mark <backendMark> return` short-circuits to skip proxying of mihomo's own traffic. |
| `networking.tproxy.table` | `18298` | systemd-networkd (`10-lo-tproxy`) | Routing-table number for the fwmark policy rule. Distinct from any existing table (e.g. whale's now-dead 700). |

**Do not collapse these into one mark.** We tried; mihomo's upstream dials
got caught by the policy routing and deadlocked ("network is unreachable").

## Packet flow

### Local host outbound (desktops, whale)

```
app → socket → kernel
             ↓
       output chain (type route, mangle)
         bypass4 check | skip cgroups | meta mark <backendMark> return (mihomo's own traffic)
         tcp/udp dport match → meta mark set <mark>
             ↓
       type route re-runs routing → ip rule fwmark <mark> → table <table>
         local default dev lo
             ↓
       packet reappears on lo ingress → PREROUTING hook
             ↓
       divert chain (priority mangle-5): socket transparent 1 accept
         (catches return-path of already-tproxied flows)
             ↓
       prerouting chain (mangle)
         bypass4 check | fib daddr type local return
         iifname "lo" jump redirect_output
             ↓
       redirect_output: tproxy ip to :<port> meta mark set <mark>
             ↓
       mihomo transparent socket accepts → sniffer → rules engine → DIRECT/proxy
```

### Forwarded (container)

```
container → veth → bridge (dockerbr / pme-*) → whale/host ns
             ↓
       PREROUTING hook on dockerbr
             ↓
       divert chain (socket transparent 1 accept) — usually no match
             ↓
       prerouting chain
         bypass4 check (RFC1918 → return)
         fib daddr type local return (destined to whale itself → return)
         iifname @forward jump redirect_forward
             ↓
       redirect_forward: tproxy ip to :<port> meta mark set <mark>
         (the `meta mark set` is CRITICAL — without it the post-prerouting
          route lookup picks the normal forward path and the packet goes
          out wan0 via nat masquerade instead of being delivered locally)
             ↓
       nixos-fw rpfilter chain (priority mangle+10)
         `fib saddr . mark . iif check exists accept` — FAILS here because
           the marked fib lookup returns `dev lo`, not the packet's actual
           iif (dockerbr). Falls through.
         `jump rpfilter-allow` → our exemption: `meta mark <mark> accept`
           (widened from the earlier `iifname "lo" meta mark ..` version
            which only covered the local-reinject path)
             ↓
       post-prerouting route lookup with mark → local delivery
             ↓
       mihomo socket accepts
```

## Gotchas

1. **`tproxy` is a reserved keyword in nft.** Naming a table `tproxy` makes
   `nft -f` parse it as the statement and fail with `unexpected tproxy,
   expecting string`. Use `ttproxy` or any non-keyword name.

2. **bypass4 interval set rejects overlaps.** `240.0.0.0/4` (reserved range)
   already contains `255.255.255.255/32`, so both together trigger
   `conflicting intervals specified`. Keep the broader entry, drop the
   narrower one.

3. **`meta mark set <mark>` is required in the prerouting tproxy rule for
   forwarded traffic.** Without the mark, the kernel's post-prerouting route
   lookup (`ip_route_input_slow`) uses the main table and picks the forward
   path because dst is non-local. With the mark, `fib lookup` matches the
   policy rule → table `<N>` → `local default dev lo` → local delivery to
   the transparent socket. Output-reinject path already has the mark set by
   the output chain, so the rule is idempotent there.

4. **The NixOS `rpfilter` chain (priority mangle+10, policy drop) drops
   tproxied packets by default**, because its `fib saddr . mark . iif check
   exists accept` rule fails when the marked fib lookup returns `dev lo`
   but the packet's actual iif is something else. Fix: add an exemption to
   `rpfilter-allow` that matches the mark alone:
   `networking.firewall.extraReversePathFilterRules = "meta mark <mark> accept";`
   Safe because only our own nft rules set that mark and SO_MARK needs
   CAP_NET_ADMIN.

5. **Mihomo refuses to dial the host's own IP** with `reject loopback
   connection to: <addr>:<port>`. This breaks any container reaching a
   local nginx reverse-proxy on whale's WAN IP. Fix: `fib daddr type local
   return` at the top of the prerouting chain so packets destined to any
   host-owned address skip tproxy entirely and take the normal
   input/forward path.

6. **Mihomo's cgroup-based loop prevention is unreliable.** nft resolves
   cgroup paths to numeric IDs at rule-load time, so the target cgroup must
   already exist — impossible at fresh boot. Attempting to use
   `socket cgroupv2 level N "system.slice/<service>"` fails the build with
   `cgroupv2 path fails: No such file or directory`. Use the mark-based
   loop guard (`routing-mark` in mihomo yaml matching `backendMark` in nft)
   instead.

7. **Mihomo's `listen: 0.0.0.0` is misleading**: empirically it still
   creates an IPv6 dual-stack socket on `[::]`. Fine for our use, but
   means `listen: "::"` or omitted is functionally identical. The `ss -4`
   listener table is empty; the socket lives in `/proc/<pid>/net/tcp6`.

8. **Mihomo's `tproxy-port` top-level key binds to `[::]` unless the
   `listeners:` section is used**. The `listeners:` entry is the only way
   to pin the tproxy socket to an explicit address if you ever need to.

9. **Upstream `services.mihomo` runs with `PrivateUsers=true` and no
   `CAP_NET_ADMIN` by default**, which breaks `IP_TRANSPARENT` bind.
   The only upstream switch to flip all three (ambient CAP_NET_ADMIN,
   PrivateUsers=false, AF_NETLINK allowed) is `services.mihomo.tunMode = true`
   — the name is misleading, we're not using mihomo's TUN device.

10. **`ExecStartPre` with `+` prefix runs as root** and creates files
    root-owned, which a DynamicUser mihomo cannot read. Drop the `+` so
    the pre-script runs as the service's dynamic user, which owns the
    `RuntimeDirectory=mihomo`.

11. **metacubexd's bundled `config.js` sets `defaultBackendURL: ""`**
    which means the dashboard falls through to hardcoded `127.0.0.1:9090`
    — useless when accessed from a nebula peer. Fix: overlay
    `pkgs.metacubexd` with a `runCommand` that rewrites `config.js` to
    `defaultBackendURL: window.location.origin`. Seeds fresh users; stale
    localStorage overrides it.

12. **Agenix files in a submodule must be `git add`-ed before the flake
    can see them**, even without committing. Otherwise Nix eval errors
    with `path ... does not exist`.

13. **`git rebase -i` is interactive-only and forbidden in this repo.**
    Same for `git add -i`. Use explicit `git add <path>` instead.

14. **`nh os switch` fails hard at build time if any `skipCgroups` path
    is invalid** — `nft -c -f` in the checkPhase runs on the builder
    where the target cgroup doesn't exist. Use build-time failure as a
    safety net, but prefer mark-based bypass which has no such issue.

## Useful commands

### Deployment

```bash
# Build on alligator (current host) and switch
nh os switch

# Deploy to another host (builds on the TARGET host, not locally)
./deploy.sh <hostname> switch
./deploy.sh <hostname> build           # just build, don't activate

# Never do: nix build .#nixosConfigurations.<other>.config.system.build.toplevel
# Never do: nh os build -H <other>
```

### nftables inspection

```bash
# See what our tproxy module emitted
sudo nft list table inet ttproxy

# Full ruleset including nixos-fw and nixos-nat
sudo nft list ruleset

# Chains only, with handles (for targeted rule removal)
sudo nft --handle list table inet ttproxy

# Which bypass CIDRs are in effect
sudo nft list set inet ttproxy bypass4
sudo nft list set inet ttproxy bypass6

# rpfilter exemption (our addition)
sudo nft list chain inet nixos-fw rpfilter-allow
```

### Tracing packet flow

```bash
# Insert a trace rule on all packets hitting prerouting
sudo nft insert rule inet ttproxy prerouting meta nftrace set 1

# Watch all trace events
sudo nft monitor trace

# Cleanup (read handle from --handle list)
sudo nft delete rule inet ttproxy prerouting handle <N>
```

### Sockets and listeners

```bash
# All mihomo listeners
sudo ss -tlnp "sport = :18298 or sport = :8080 or sport = :1080 or sport = :9090"

# Which family does the socket actually live in?
sudo ss -4 -tlnp "sport = :18298"     # empty means no IPv4 socket
sudo ss -6 -tlnp "sport = :18298"     # IPv6 dual-stack if v6only:0
cat /proc/<mihomo-pid>/net/tcp6       # raw kernel state

# Verify mihomo service unit is actually running
systemctl status mihomo
journalctl -u mihomo -f --no-pager
```

### Policy routing

```bash
# Our fwmark rule should be there
ip rule show | grep fwmark

# The local-default route that makes the lo trick work
ip route show table 18298

# Simulate what the kernel will do for a given packet
ip route get <dst> from <src> iif <in-iface> mark 0x477a
```

### Mihomo REST API (via nebula)

```bash
# Base URL (replace with host's nebula IP)
MIHOMO=http://10.57.1.41:9090

# Config snapshot
curl -sS $MIHOMO/configs | jq

# Proxy groups
curl -sS $MIHOMO/proxies | jq '.proxies | to_entries[] | select(.value.type=="Selector") | "\(.key) [now=\(.value.now)]"' -r

# Switch a selector (stays until cache.db cleared or manually changed)
curl -sS -X PUT -H 'Content-Type: application/json' -d '{"name":"Proxy"}' $MIHOMO/proxies/GLOBAL

# Rule count and first N rules
curl -sS $MIHOMO/rules | jq '.rules | length'

# Rule-provider status
curl -sS $MIHOMO/providers/rules | jq '.providers | to_entries[] | "\(.key): \(.value.ruleCount) rules"' -r

# Dashboard
# http://10.57.1.41:9090/ui/  (defaultBackendURL = window.location.origin)
```

### Testing traffic end-to-end

```bash
# Via transparent intercept (tproxy'd automatically)
curl -sS -o /dev/null -w "%{http_code} ip=%{remote_ip}\n" https://api.ipify.org

# Via explicit HTTP proxy
curl -sS -x http://127.0.0.1:8080 https://api.ipify.org

# Via SOCKS5 with remote-resolved hostname
curl -sS --socks5-hostname 127.0.0.1:1080 https://api.ipify.org

# HTTP/3 (UDP 443) — only if curl has nghttp3/ngtcp2
curl -sS --http3-only -o /dev/null -w "proto=%{http_version}\n" https://cloudflare.com/
```

### nspawn container debugging on whale

```bash
# List nspawn containers
sudo machinectl list

# Get a container's init PID
DOCKER_PID=$(sudo machinectl show docker -p Leader --value)

# Non-interactive shell inside the container's network namespace
sudo nsenter -t $DOCKER_PID -n -- /run/current-system/sw/bin/curl -sS https://...

# Run a command inside a container, getting stdout (no pty issues)
sudo nsenter -t $DOCKER_PID -a -- /run/current-system/sw/bin/docker ps

# Same but inside a docker container inside the nspawn
sudo nsenter -t $DOCKER_PID -a -- /run/current-system/sw/bin/docker exec <name> curl -sS https://...

# Packet capture on a specific bridge
sudo timeout 5 tcpdump -nni dockerbr -c 20 "tcp port 443"
```

### Recovery from a broken tproxy deploy

```bash
# If nftables got into a bad state and blocks outbound,
# flush the ttproxy table manually (survives until next deploy)
ssh <host> 'sudo nft delete table inet ttproxy'

# Verify internet is back
ssh <host> 'curl -sS -o /dev/null -w "%{http_code}\n" https://cloudflare.com/'

# Then redeploy — the nftables-rules derivation will recreate the table
./deploy.sh <host> switch
```

### Agenix secret management

```bash
# Add an entry to secrets.nix with the right recipients, then:
agenix -e secrets/mihomo/<name>.age            # opens $EDITOR

# Non-interactive write from a file:
tmp=$(mktemp); chmod 600 "$tmp"
printf 'KEY=value\n' > "$tmp"
EDITOR="cp $tmp" agenix -e secrets/mihomo/<name>.age
shred -u "$tmp"

# Re-encrypt all secrets with new recipients after editing secrets.nix
agenix --rekey

# Remember: files in the secrets/ submodule must be `git add`-ed before
# Nix flake eval can see them. Commit is optional but tracking is required.
cd secrets && git add mihomo/<name>.age && cd -
```

### systemd credentials + envsubst pattern (for secret interpolation)

Used in `roles/core/mihomo.nix` to substitute `${AKENAI_URL}` into the
generated yaml at service start without putting the URL in the Nix store:

```nix
age.secrets.mihomo-akenai-url.file = "${secrets}/mihomo/akenai-url.age";

systemd.services.mihomo.serviceConfig = {
  RuntimeDirectory = "mihomo";
  RuntimeDirectoryMode = "0700";
  EnvironmentFile = config.age.secrets.mihomo-akenai-url.path;
  ExecStartPre = lib.mkBefore [
    (pkgs.writeShellScript "mihomo-envsubst" ''
      set -eu
      ${pkgs.envsubst}/bin/envsubst '$AKENAI_URL' \
        < "$CREDENTIALS_DIRECTORY/config.yaml" \
        > /run/mihomo/config.yaml
    '')
  ];
  ExecStart = lib.mkForce "${lib.getExe config.services.mihomo.package} -d /var/lib/private/mihomo -f /run/mihomo/config.yaml -ext-ui ${metacubexdAuto}";
};
```

Secret format (one `KEY=value` per line, shell env syntax):
```
AKENAI_URL=https://api.akenai.ru/c/<token>
```

## References

- [mihomo wiki](https://wiki.metacubex.one/)
- [Linux TPROXY kernel docs](https://docs.kernel.org/networking/tproxy.html)
- [nftables tproxy statement](https://wiki.nftables.org/wiki-nftables/index.php/Tproxy)
- [mihomo source: adapter/provider/override.go](https://github.com/MetaCubeX/mihomo/blob/Alpha/adapter/provider/override.go) — authoritative list of proxy-provider override fields
- [mihomo source: tunnel/tunnel.go](https://github.com/MetaCubeX/mihomo/blob/Alpha/tunnel/tunnel.go) — fallback-to-DIRECT when no rule matches
- [hev.cc: Transparent Proxy with nftables](https://hev.cc/posts/2021/transparent-proxy-with-nftables/)
- [scenery/mihomo-tproxy-docker](https://github.com/scenery/mihomo-tproxy-docker) — reference nft ruleset
