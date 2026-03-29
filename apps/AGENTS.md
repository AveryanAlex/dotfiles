# APPS KNOWLEDGE BASE

## OVERVIEW

`apps/` holds Quadlet/Podman services imported by `machines/whale/default.nix`.
Use this tree for containerized services; native NixOS services belong in `profiles/server/`.

## WHERE TO LOOK

| Need | File |
|------|------|
| Simple app + db pattern | `litellm/default.nix`, `wakapi/default.nix` |
| Multi-container web app | `nextcloud/default.nix` |
| Host-user file access | `navidrome/default.nix`, `slskd/default.nix` |
| TProxy / firewall extras | `lidarr/default.nix`, `prowlarr/default.nix`, `newsrelay/default.nix` |
| Multi-instance generation | `navidrome/default.nix`, `reelsgen/default.nix` |
| Private GHCR images | `cinemabot/default.nix`, `s2sbot/default.nix`, `reelsgen/default.nix` |

## CONVENTIONS

- Prefer `let name = "appname"; in { config, ... }:`. A few older files reverse the order; follow local style when editing them.
- One app directory = one `default.nix` entrypoint plus optional local `.age` files and config assets.
- Most apps set `podmanArgs = [ "--interface-name=pme-${name}" ]`; keep existing local exceptions like `cinemabot` as-is.
- Explicit subnets use `10.90.X.0/24`. Static IPs follow `.2` = app, `.3` = db, `.4` = cache/secondary.
- `reelsgen` is the one current no-subnet exception; do not copy that pattern unless the app really relies on Podman's auto-assigned network.
- Use `autoUpdate = "registry"` on containers unless you are intentionally pinning or disabling updates, and explain the exception inline.
- Set `containerConfig.memory` (Podman native `--memory`) for app containers. Avoid leaving large app containers unbounded.
- Web apps usually define their own nginx vhost here with `useACMEHost = "averyan.ru"`, `forceSSL = true`, and `proxyWebsockets = true`. `mtproto` is the raw-TCP exception.
- Keep app secrets next to the app (`./*.age`), but still add their ACL entries to root `secrets.nix`.
- Dependent sidecars use `unitConfig = rec { Requires = [...]; After = Requires; };`.
- App persistence is usually created with `systemd.tmpfiles.rules` under `/persist/${name}/...`, not host `persist.state.*`.

## SUBNET REGISTRY

| Subnet | App |
|--------|-----|
| `10.90.85.0/24` | `s2sbot` |
| `10.90.86.0/24` | `wakapi` |
| `10.90.87.0/24` | `cinemabot` |
| `10.90.88.0/24` | `nextcloud` |
| `10.90.89.0/24` | `newsrelay` |
| `10.90.90.0/24` | `lidarr` |
| `10.90.91.0/24` | `slskd` |
| `10.90.92.0/24` | `navidrome` |
| `10.90.93.0/24` | `prowlarr` |
| `10.90.94.0/24` | `mtproto` |
| `10.90.95.0/24` | `litellm` |

`reelsgen` currently omits an explicit subnet. If you need a new explicit app network, pick an unused `/24` after checking this table; `10.90.84.0/24` and `10.90.96.0/24+` are currently unused in `apps/`.

## UID/GID MAPS

### Rootless standard

Use this when the container runs as container-root and does not need host user file ownership:

```nix
gidMaps = [ "0:100000:100000" ];
uidMaps = [ "0:100000:100000" ];
```

Matching tmpfiles ownership is usually `100999:100999`.

### Host-user passthrough

Use this when the container must read or write files owned by `alex` (`uid 1000`, `gid 100`):

```nix
gidMaps = [ "0:100000:100" "100:100:1" "101:100101:98999" ];
uidMaps = [ "0:100000:1000" "1000:1000:1" "1001:101001:98999" ];
```

Matching tmpfiles ownership is usually `1000:100`.

### Special case

`wakapi` uses `101000:101000` ownership for app data. Follow that file if you need a container that runs as a non-root internal UID without mapping straight to host `alex`.

## NETWORKING EXTRAS

- `networking.tproxy.forward.interfaces = [ "pme-${name}" ]` for proxied outbound traffic (`lidarr`, `prowlarr`, `newsrelay`).
- `networking.firewall.interfaces."pme-${name}".allowedTCPPorts` for exposing specific ports on the app network (`lidarr`, `prowlarr`, `reelsgen`).
- `networking.nat.forwardPorts` for host-to-container external forwarding (`slskd`).
- `networking.firewall.extraForwardRules` for cross-app traffic (`lidarr` → `slskd`).

## PRIVATE REGISTRIES

Apps pulling from private `ghcr.io` images set:

```nix
serviceConfig.Environment = [
  "REGISTRY_AUTH_FILE=${config.environment.sessionVariables.REGISTRY_AUTH_FILE}"
];
```

Use that pattern for private images; public images do not need it.

## ANTI-PATTERNS

- Do not reuse an allocated `/24` subnet.
- Do not mix host-user UID maps with `100999:100999` tmpfiles ownership.
- Do not move reusable native services here just because they run on whale; keep those in `profiles/server/`.
