# Transparent proxy module (kernel TPROXY)
#
# Emits nftables rules and policy routing so a local backend (mihomo, or xray
# in tproxy mode) can intercept TCP and UDP traffic via IP_TRANSPARENT sockets.
# Unlike REDIRECT-based transparent proxying, TPROXY does not rewrite packet
# headers, so the original destination is preserved for both TCP and UDP. Local
# output traffic is handled via a fwmark + policy-routing re-injection trick
# (mark -> table -> `local default dev lo` -> prerouting -> tproxy).
{
  lib,
  config,
  ...
}:
let
  inherit (lib)
    attrNames
    concatMapStringsSep
    concatStringsSep
    filter
    hasInfix
    length
    literalExpression
    mapAttrsToList
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalString
    splitString
    types
    ;

  cfg = config.networking.tproxy;

  # Port spec type: accepts integers (single port) and strings (ranges like
  # "8000-9000"). Rendered to nftables set syntax: { 80, 443, 8000-9000 }
  portSpec = types.listOf (types.either types.port types.str);

  renderPort = p: if builtins.isInt p then toString p else p;
  renderPorts = ps: concatStringsSep ", " (map renderPort ps);

  defaultBypass4 = [
    "0.0.0.0/8"
    "10.0.0.0/8"
    "127.0.0.0/8"
    "169.254.0.0/16"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "224.0.0.0/4"
    "240.0.0.0/4"
    # 255.255.255.255/32 intentionally omitted: already covered by 240.0.0.0/4,
    # and nftables rejects overlapping intervals.
  ];

  defaultBypass6 = [
    "::1/128"
    "fc00::/7"
    "fe80::/10"
    "ff00::/8"
  ];

  bypass4 = defaultBypass4 ++ cfg.extraBypassCIDRs.ipv4;
  bypass6 = defaultBypass6 ++ cfg.extraBypassCIDRs.ipv6;

  # Naive family classifier: any CIDR containing ':' is IPv6
  isV6 = s: hasInfix ":" s;
  v4Of = filter (s: !isV6 s);
  v6Of = filter isV6;

  commaList = xs: concatStringsSep ", " xs;

  hasForward = cfg.forward != { };
  hasOutput = cfg.output.enable;
  forwardIfaces = attrNames cfg.forward;

  # Resolution: field overrides defaults (or null = use defaults), then
  # extra* is appended. `any`/`extraAny` feeds into both tcp and udp.
  resolve =
    {
      tcp,
      extraTcp,
      udp,
      extraUdp,
      any,
      extraAny,
      srcCIDRs,
      extraSrcCIDRs,
    }:
    let
      anyResolved = (if any != null then any else cfg.defaults.any) ++ extraAny;
    in
    {
      tcpPorts = (if tcp != null then tcp else cfg.defaults.tcp) ++ extraTcp ++ anyResolved;
      udpPorts = (if udp != null then udp else cfg.defaults.udp) ++ extraUdp ++ anyResolved;
      srcCIDRs = (if srcCIDRs != null then srcCIDRs else cfg.defaults.srcCIDRs) ++ extraSrcCIDRs;
    };

  # Output also resolves skipUsers/skipCgroups from defaults
  outputSkipUsers =
    (if cfg.output.skipUsers != null then cfg.output.skipUsers else cfg.defaults.skipUsers)
    ++ cfg.output.extraSkipUsers;
  outputSkipCgroups =
    (if cfg.output.skipCgroups != null then cfg.output.skipCgroups else cfg.defaults.skipCgroups)
    ++ cfg.output.extraSkipCgroups;

  outputResolved = resolve {
    inherit (cfg.output)
      tcp
      extraTcp
      udp
      extraUdp
      any
      extraAny
      srcCIDRs
      extraSrcCIDRs
      ;
  };

  resolveIface =
    name:
    let
      ic = cfg.forward.${name};
    in
    resolve {
      inherit (ic)
        tcp
        extraTcp
        udp
        extraUdp
        any
        extraAny
        srcCIDRs
        extraSrcCIDRs
        ;
    };

  # Generate tproxy rules for a given resolved config. `meta mark set` after
  # tproxy is required for forwarded traffic: without it the kernel's route
  # lookup picks the forward path instead of local delivery.
  mkTproxyRules =
    {
      tcpPorts,
      udpPorts,
    }:
    let
      tcpDport = if tcpPorts == [ ] then "" else " tcp dport { ${renderPorts tcpPorts} }";
      udpDport = if udpPorts == [ ] then "" else " udp dport { ${renderPorts udpPorts} }";
    in
    (optionalString (tcpPorts != [ ]) ''
      meta nfproto ipv4 meta l4proto tcp${tcpDport} tproxy ip to :${toString cfg.port} meta mark set ${toString cfg.mark}
      meta nfproto ipv6 meta l4proto tcp${tcpDport} tproxy ip6 to :${toString cfg.port} meta mark set ${toString cfg.mark}
    '')
    + (optionalString (udpPorts != [ ]) ''
      meta nfproto ipv4 meta l4proto udp${udpDport} tproxy ip to :${toString cfg.port} meta mark set ${toString cfg.mark}
      meta nfproto ipv6 meta l4proto udp${udpDport} tproxy ip6 to :${toString cfg.port} meta mark set ${toString cfg.mark}
    '');

  # Mark-set rules for the output chain (no tproxy statement — that happens
  # in redirect_output after re-injection via lo).
  mkMarkRules =
    {
      tcpPorts,
      udpPorts,
    }:
    let
      tcpDport = if tcpPorts == [ ] then "" else " tcp dport { ${renderPorts tcpPorts} }";
      udpDport = if udpPorts == [ ] then "" else " udp dport { ${renderPorts udpPorts} }";
    in
    (optionalString (tcpPorts != [ ]) ''
      meta l4proto tcp${tcpDport} meta mark set ${toString cfg.mark}
    '')
    + (optionalString (udpPorts != [ ]) ''
      meta l4proto udp${udpDport} meta mark set ${toString cfg.mark}
    '');

  # Source-CIDR filter: when set, only traffic whose source matches one of the
  # CIDRs passes through. Empty list means no filter.
  mkSrcFilter =
    cidrs:
    let
      v4 = v4Of cidrs;
      v6 = v6Of cidrs;
    in
    optionalString (cidrs != [ ]) (
      (
        if v4 != [ ] then
          ''
            meta nfproto ipv4 ip saddr != { ${commaList v4} } return
          ''
        else
          ''
            meta nfproto ipv4 return
          ''
      )
      + (
        if v6 != [ ] then
          ''
            meta nfproto ipv6 ip6 saddr != { ${commaList v6} } return
          ''
        else
          ''
            meta nfproto ipv6 return
          ''
      )
    );

  # nftables cgroupv2 level is the number of path components in the cgroup.
  mkSkipCgroup =
    g:
    let
      level = length (splitString "/" g);
    in
    ''socket cgroupv2 level ${toString level} "${g}" return'';

  # Resolve username to numeric UID at Nix eval time so nft doesn't need
  # /etc/passwd at rule-load time (fails in build sandbox and on fresh boot
  # before user creation). Accepts strings (looked up via config.users.users)
  # or ints (used directly).
  mkSkipUser =
    u:
    let
      uid = if builtins.isInt u then u else config.users.users.${u}.uid;
    in
    "meta skuid ${toString uid} return  # ${toString u}";

  # Shared option set used by both output and each forward.<iface> submodule.
  # Each field: null = inherit defaults, [] = clear, explicit = override.
  # extra*: always appended to the resolved base.
  # `.any`/`.extraAny` is a convenience that appends to BOTH tcp and udp.
  interceptOpts = {
    tcp = mkOption {
      type = types.nullOr portSpec;
      default = null;
      example = literalExpression ''[ 80 443 "8000-9000" ]'';
      description = "TCP ports. null = use defaults.tcp. [] = disable TCP.";
    };
    extraTcp = mkOption {
      type = portSpec;
      default = [ ];
      description = "Extra TCP ports appended after resolving tcp.";
    };
    udp = mkOption {
      type = types.nullOr portSpec;
      default = null;
      description = "UDP ports. null = use defaults.udp. [] = disable UDP.";
    };
    extraUdp = mkOption {
      type = portSpec;
      default = [ ];
      description = "Extra UDP ports appended after resolving udp.";
    };
    any = mkOption {
      type = types.nullOr portSpec;
      default = null;
      description = "Ports for both TCP and UDP. null = use defaults.any. Appended to both resolved tcp and udp.";
    };
    extraAny = mkOption {
      type = portSpec;
      default = [ ];
      description = "Extra ports appended to both TCP and UDP after resolution.";
    };
    srcCIDRs = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "Source CIDRs. null = use defaults. [] = match any source.";
    };
    extraSrcCIDRs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra source CIDRs appended after resolving srcCIDRs.";
    };
  };

  forwardIfaceOpts = types.submodule { options = interceptOpts; };
in
{
  options.networking.tproxy = {
    enable = mkEnableOption "transparent proxy plumbing (kernel TPROXY)";

    port = mkOption {
      type = types.port;
      default = 18298;
      description = "Port the transparent-proxy backend listens on for intercepted connections.";
    };

    mark = mkOption {
      type = types.int;
      default = 18298;
      description = ''
        Firewall mark used exclusively for policy routing of local output
        traffic and forwarded traffic delivery. Must NOT collide with marks
        used by other subsystems, and must NOT be set externally by the
        backend (use `backendMark` for that).
      '';
    };

    backendMark = mkOption {
      type = types.int;
      default = 18299;
      description = ''
        Firewall mark the backend (mihomo, xray) sets via SO_MARK on its own
        upstream connections. Must differ from `mark` so the kernel's policy
        routing rule does NOT catch the backend's upstream.
      '';
    };

    table = mkOption {
      type = types.int;
      default = 18298;
      description = "Routing table number used to local-deliver marked output traffic via lo.";
    };

    defaults = {
      tcp = mkOption {
        type = portSpec;
        default = [ "1-65535" ];
        example = literalExpression ''[ 80 443 "8000-9000" ]'';
        description = "Default TCP ports inherited by output and forward unless overridden.";
      };
      udp = mkOption {
        type = portSpec;
        default = [ "1-65535" ];
        description = "Default UDP ports inherited by output and forward unless overridden.";
      };
      any = mkOption {
        type = portSpec;
        default = [ ];
        description = "Default ports for both TCP and UDP. Appended to both resolved tcp and udp lists.";
      };
      srcCIDRs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Default source CIDRs inherited unless overridden. Empty = match any source.";
      };
      skipUsers = mkOption {
        type = types.listOf (types.either types.str types.int);
        default = [ ];
        description = "Default users whose outbound traffic bypasses tproxy. Inherited by output unless overridden.";
      };
      skipCgroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Default cgroups whose sockets bypass tproxy. Inherited by output unless overridden.";
      };
    };

    skipDomains = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = literalExpression ''[ "akenai.ru" "akenai.click" ]'';
      description = ''
        Domain suffixes whose traffic should always go DIRECT, never through
        the proxy. The backend module (e.g. mihomo) reads this and prepends
        DOMAIN-SUFFIX rules before user-defined rules. Use for proxy provider
        domains to prevent circular routing.
      '';
    };

    skipExactDomains = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Exact domain names whose traffic should always go DIRECT. Same as
        skipDomains but matches the full domain, not suffixes.
      '';
    };

    skipPorts = {
      tcp = mkOption {
        type = portSpec;
        default = [ ];
        example = literalExpression ''[ 22 25 "8362-8364" ]'';
        description = "TCP ports that bypass tproxy entirely (never proxied).";
      };
      udp = mkOption {
        type = portSpec;
        default = [ ];
        example = literalExpression ''[ 53 "60000-61000" ]'';
        description = "UDP ports that bypass tproxy entirely.";
      };
      any = mkOption {
        type = portSpec;
        default = [ ];
        example = literalExpression "[ 4242 ]";
        description = "Ports that bypass tproxy for both TCP and UDP.";
      };
    };

    extraBypassCIDRs = {
      ipv4 = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra IPv4 CIDRs added to the bypass set alongside RFC1918/loopback/link-local/multicast defaults.";
      };
      ipv6 = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra IPv6 CIDRs added to the bypass set alongside loopback/ULA/link-local/multicast defaults.";
      };
    };

    output = interceptOpts // {
      enable = mkEnableOption "transparent proxy for this host's own outbound traffic";

      skipUsers = mkOption {
        type = types.nullOr (types.listOf (types.either types.str types.int));
        default = null;
        example = literalExpression ''[ "yggdrasil" ]'';
        description = "Users bypassing tproxy. null = use defaults.skipUsers. [] = clear.";
      };
      extraSkipUsers = mkOption {
        type = types.listOf (types.either types.str types.int);
        default = [ ];
        description = "Extra users appended after resolving skipUsers.";
      };

      skipCgroups = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        example = literalExpression ''[ "system.slice/mihomo.service" ]'';
        description = ''
          Cgroups bypassing tproxy. null = use defaults.skipCgroups. [] = clear.
          nft resolves paths at load time (chicken-and-egg at boot).
        '';
      };
      extraSkipCgroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Extra cgroups appended after resolving skipCgroups.";
      };
    };

    forward = mkOption {
      type = types.attrsOf forwardIfaceOpts;
      default = { };
      example = literalExpression ''
        {
          "dockerbr" = { tcpPorts = [ "1-65535" ]; };  # all TCP
          "pme-lidarr" = {};                            # use defaults
        }
      '';
      description = ''
        Per-interface forwarded traffic interception. Keys are interface names.
        Each entry inherits from `defaults` unless fields are explicitly set.
        An empty attrset `{}` means "use all defaults for this interface".
      '';
    };
  };

  config = mkIf cfg.enable {
    # Required for the `tproxy` and `socket` nftables statements
    boot.kernelModules = [
      "nft_tproxy"
      "nft_socket"
    ];

    # Name avoids the `tproxy` keyword which nft's parser would consume as the
    # tproxy statement instead of as an identifier.
    networking.nftables.tables.ttproxy = {
      family = "inet";
      content = ''
        set bypass4 {
          type ipv4_addr
          flags interval
          elements = { ${commaList bypass4} }
        }
        set bypass6 {
          type ipv6_addr
          flags interval
          elements = { ${commaList bypass6} }
        }

        # Divert catches packets that already belong to an existing transparent
        # socket (established flows). Runs before the main prerouting chain so
        # those packets skip the tproxy statement entirely.
        chain divert {
          type filter hook prerouting priority mangle - 5; policy accept;
          meta l4proto { tcp, udp } socket transparent 1 accept
        }

        chain prerouting {
          type filter hook prerouting priority mangle; policy accept;
          ip daddr @bypass4 return
          ip6 daddr @bypass6 return
          # Packets destined to any of the host's own addresses (WAN, LAN,
          # lo, nebula, bridges) must skip tproxy so locally-hosted services
          # like nginx reverse-proxies work.
          fib daddr type local return
          ${
            let
              skipTcp = cfg.skipPorts.tcp ++ cfg.skipPorts.any;
            in
            optionalString (skipTcp != [ ]) ''
              tcp dport { ${renderPorts skipTcp} } return
            ''
          }
          ${
            let
              skipUdp = cfg.skipPorts.udp ++ cfg.skipPorts.any;
            in
            optionalString (skipUdp != [ ]) ''
              udp dport { ${renderPorts skipUdp} } return
            ''
          }
          ${concatStringsSep "\n    " (map (iface: ''iifname "${iface}" jump fwd-${iface}'') forwardIfaces)}
          ${optionalString hasOutput ''
            iifname "lo" jump redirect_output
          ''}
        }

        ${concatStringsSep "\n" (
          map (
            iface:
            let
              resolved = resolveIface iface;
            in
            ''
              chain fwd-${iface} {
                ${mkSrcFilter resolved.srcCIDRs}
                ${mkTproxyRules { inherit (resolved) tcpPorts udpPorts; }}
              }
            ''
          ) forwardIfaces
        )}

        ${optionalString hasOutput ''
          chain redirect_output {
            ${mkSrcFilter outputResolved.srcCIDRs}
            ${mkTproxyRules {
              tcpPorts = outputResolved.tcpPorts;
              udpPorts = outputResolved.udpPorts;
            }}
          }

          chain output {
            type route hook output priority mangle; policy accept;
            ip daddr @bypass4 return
            ip6 daddr @bypass6 return

            # Skip reply packets for inbound connections (SSH, nginx, etc.)
            # so only locally-initiated outbound flows get proxied.
            # Note: conntrack UDP timeout is 30s (120s bidirectional) by default;
            # if an entry expires, the next reply won't match. Tune via
            # net.netfilter.nf_conntrack_udp_timeout{,_stream} if needed.
            ct direction reply return

            # Loop guard: backend set SO_MARK = backendMark on its own upstream
            # connection, skip us.
            meta mark ${toString cfg.backendMark} return

            ${
              let
                skipTcp = cfg.skipPorts.tcp ++ cfg.skipPorts.any;
              in
              optionalString (skipTcp != [ ]) ''
                tcp dport { ${renderPorts skipTcp} } return
              ''
            }
            ${
              let
                skipUdp = cfg.skipPorts.udp ++ cfg.skipPorts.any;
              in
              optionalString (skipUdp != [ ]) ''
                udp dport { ${renderPorts skipUdp} } return
              ''
            }
            ${concatMapStringsSep "\n    " mkSkipCgroup outputSkipCgroups}
            ${concatMapStringsSep "\n    " mkSkipUser outputSkipUsers}
            ${mkSrcFilter outputResolved.srcCIDRs}
            ${mkMarkRules {
              tcpPorts = outputResolved.tcpPorts;
              udpPorts = outputResolved.udpPorts;
            }}
          }
        ''}
      '';
    };

    # Local delivery of re-injected output traffic: fwmark -> table -> `local
    # default dev lo`. Also needed for forwarded tproxy traffic (the mark makes
    # the kernel route the packet locally instead of forwarding).
    systemd.network.networks."10-lo-tproxy" = mkIf (hasOutput || hasForward) {
      matchConfig.Name = "lo";
      linkConfig.RequiredForOnline = false;
      routingPolicyRules = [
        {
          FirewallMark = cfg.mark;
          Table = cfg.table;
          Family = "both";
        }
      ];
      routes = [
        {
          Destination = "0.0.0.0/0";
          Type = "local";
          Table = cfg.table;
        }
        {
          Destination = "::/0";
          Type = "local";
          Table = cfg.table;
        }
      ];
    };

    # Open the backend port on forwarded interfaces so packets aren't dropped
    # by the input filter chain after tproxy has delivered them to the socket.
    networking.firewall.interfaces = mkMerge (
      map (iface: {
        ${iface} = {
          allowedTCPPorts = [ cfg.port ];
          allowedUDPPorts = [ cfg.port ];
        };
      }) forwardIfaces
    );

    # NixOS's reverse-path filter (inet nixos-fw rpfilter) drops packets whose
    # source address doesn't match the iif via FIB check. TWO cases need the
    # exemption:
    #   - Output-hook re-injection: packet comes in on lo with a LAN source,
    #     FIB check rejects.
    #   - Forwarded interfaces: after our redirect chains set the tproxy mark,
    #     the fib check uses the marked lookup which returns `local dev lo` and
    #     sees iif=lo, but the actual packet iif is e.g. dockerbr, so the check
    #     fails.
    # Both cases are caught by matching the mark alone, regardless of iif.
    # Safe because the mark is only set by our own nft rules, never by
    # external sources.
    networking.firewall.extraReversePathFilterRules = mkIf (hasOutput || hasForward) ''
      meta mark ${toString cfg.mark} accept
    '';
  };
}
