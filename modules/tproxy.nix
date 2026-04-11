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
    concatMapStringsSep
    concatStringsSep
    filter
    hasInfix
    length
    literalExpression
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalString
    splitString
    types
    ;

  cfg = config.networking.tproxy;

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
  portList = xs: concatStringsSep ", " (map toString xs);
  quoteList = xs: concatStringsSep ", " (map (s: ''"${s}"'') xs);

  hasForward = cfg.forward.interfaces != [ ];
  hasOutput = cfg.output.enable;

  # tproxy statement only works in prerouting. Emit one line per (family, l4)
  # because `inet` tables need an explicit `ip`/`ip6` qualifier on tproxy.
  mkTproxyLines =
    {
      tcpPorts,
      udpPorts,
    }:
    (optionalString (tcpPorts != [ ]) ''
      meta nfproto ipv4 meta l4proto tcp tcp dport { ${portList tcpPorts} } tproxy ip to :${toString cfg.port}
      meta nfproto ipv6 meta l4proto tcp tcp dport { ${portList tcpPorts} } tproxy ip6 to :${toString cfg.port}
    '')
    + (optionalString (udpPorts != [ ]) ''
      meta nfproto ipv4 meta l4proto udp udp dport { ${portList udpPorts} } tproxy ip to :${toString cfg.port}
      meta nfproto ipv6 meta l4proto udp udp dport { ${portList udpPorts} } tproxy ip6 to :${toString cfg.port}
    '');

  # Output-hook marking lines: set fwmark on matching packets so `type route`
  # re-runs routing, sends them via the tproxy table through lo, and they
  # re-enter prerouting where the tproxy statement above catches them.
  mkMarkLines =
    {
      tcpPorts,
      udpPorts,
    }:
    (optionalString (tcpPorts != [ ]) ''
      meta l4proto tcp tcp dport { ${portList tcpPorts} } meta mark set ${toString cfg.mark}
    '')
    + (optionalString (udpPorts != [ ]) ''
      meta l4proto udp udp dport { ${portList udpPorts} } meta mark set ${toString cfg.mark}
    '');

  # Source-CIDR filter: when set, only traffic whose source matches one of the
  # CIDRs passes through. Empty list means no filter. A single-family list
  # implicitly denies the other family.
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
  # e.g. "system.slice/mihomo.service" is level 2.
  mkSkipCgroup =
    g:
    let
      level = length (splitString "/" g);
    in
    ''socket cgroupv2 level ${toString level} "${g}" return'';

  mkSkipUser = u: ''meta skuid "${u}" return'';
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
        traffic: the nft output chain sets this mark on packets we want to
        re-inject via lo, and the `ip rule fwmark <mark> lookup <table>`
        policy routes them. Must NOT collide with marks used by other
        subsystems (e.g. WireGuard selective routing), and must NOT be set
        externally by the backend (use `backendMark` for that).
      '';
    };

    backendMark = mkOption {
      type = types.int;
      default = 18299;
      description = ''
        Firewall mark the backend (mihomo, xray) sets via SO_MARK on its own
        upstream connections, matched by the output chain's loop-prevention
        `meta mark <backendMark> return` rule. Must differ from `mark` so
        that the kernel's policy routing rule does NOT catch the backend's
        upstream and re-inject it via lo (which would deadlock the backend).
      '';
    };

    table = mkOption {
      type = types.int;
      default = 18298;
      description = "Routing table number used to local-deliver marked output traffic via lo.";
    };

    defaultTcpPorts = mkOption {
      type = types.listOf types.port;
      default = [
        80
        443
      ];
      description = "Default TCP destination ports to intercept (used when output/forward don't override).";
    };

    defaultUdpPorts = mkOption {
      type = types.listOf types.port;
      default = [ 443 ];
      description = "Default UDP destination ports to intercept (used when output/forward don't override).";
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

    output = {
      enable = mkEnableOption "transparent proxy for this host's own outbound traffic";

      tcpPorts = mkOption {
        type = types.listOf types.port;
        default = cfg.defaultTcpPorts;
        defaultText = literalExpression "config.networking.tproxy.defaultTcpPorts";
        description = "TCP ports to intercept in the output hook.";
      };

      udpPorts = mkOption {
        type = types.listOf types.port;
        default = cfg.defaultUdpPorts;
        defaultText = literalExpression "config.networking.tproxy.defaultUdpPorts";
        description = "UDP ports to intercept in the output hook.";
      };

      srcCIDRs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''[ "192.168.5.0/24" ]'';
        description = ''
          If non-empty, only local traffic whose source address matches one of
          these CIDRs is intercepted. Empty means any source.
        '';
      };

      skipUsers = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''[ "nix-daemon" "root" ]'';
        description = "Local users whose outbound traffic bypasses the proxy (matched via meta skuid).";
      };

      skipCgroups = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''[ "system.slice/mihomo.service" ]'';
        description = ''
          Systemd cgroup v2 paths whose sockets bypass the proxy, evaluated via
          `socket cgroupv2 level N "..."`. Empty by default because nft resolves
          cgroup paths at ruleset load time, so a named service must already be
          running when the firewall loads -- at fresh boot that's a chicken-and-
          egg problem. The primary loop guard for mihomo is its `routing-mark`
          (secondary) combined with the `meta mark <mark> return` check at the
          top of the output chain (primary). Only set this when the target
          service is guaranteed to exist before nftables reloads.
        '';
      };
    };

    forward = {
      interfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''[ "pme-lidarr" ]'';
        description = ''
          Interface names whose forwarded traffic is intercepted. Typically
          container or VM bridge interfaces.
        '';
      };

      tcpPorts = mkOption {
        type = types.listOf types.port;
        default = cfg.defaultTcpPorts;
        defaultText = literalExpression "config.networking.tproxy.defaultTcpPorts";
        description = "TCP ports to intercept on forwarded interfaces.";
      };

      udpPorts = mkOption {
        type = types.listOf types.port;
        default = cfg.defaultUdpPorts;
        defaultText = literalExpression "config.networking.tproxy.defaultUdpPorts";
        description = "UDP ports to intercept on forwarded interfaces.";
      };

      srcCIDRs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "If non-empty, only forwarded traffic whose source address matches one of these CIDRs is intercepted.";
      };
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
          ${optionalString hasForward ''
            iifname { ${quoteList cfg.forward.interfaces} } jump redirect_forward
          ''}
          ${optionalString hasOutput ''
            iifname "lo" jump redirect_output
          ''}
        }

        ${optionalString hasForward ''
          chain redirect_forward {
            ${mkSrcFilter cfg.forward.srcCIDRs}
            ${mkTproxyLines {
              inherit (cfg.forward) tcpPorts udpPorts;
            }}
          }
        ''}

        ${optionalString hasOutput ''
          chain redirect_output {
            ${mkSrcFilter cfg.output.srcCIDRs}
            ${mkTproxyLines {
              inherit (cfg.output) tcpPorts udpPorts;
            }}
          }

          chain output {
            type route hook output priority mangle; policy accept;
            ip daddr @bypass4 return
            ip6 daddr @bypass6 return

            # Loop guard: backend set SO_MARK = backendMark on its own upstream
            # connection, skip us.
            meta mark ${toString cfg.backendMark} return

            ${concatMapStringsSep "\n    " mkSkipCgroup cfg.output.skipCgroups}
            ${concatMapStringsSep "\n    " mkSkipUser cfg.output.skipUsers}
            ${mkSrcFilter cfg.output.srcCIDRs}
            ${mkMarkLines {
              inherit (cfg.output) tcpPorts udpPorts;
            }}
          }
        ''}
      '';
    };

    # Local delivery of re-injected output traffic: fwmark -> table -> `local
    # default dev lo`. Attached to the lo link because that's where the local
    # routes live; the routing policy rules themselves are global.
    systemd.network.networks."10-lo-tproxy" = mkIf hasOutput {
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
      }) cfg.forward.interfaces
    );

    # NixOS's reverse-path filter (inet nixos-fw rpfilter) drops packets whose
    # source address doesn't match the iif via FIB check. Our output-hook
    # re-injection sends packets with a LAN source address back in through lo,
    # which the FIB lookup does not accept as a valid reverse path. Whitelist
    # our marked traffic so those legitimate re-injected packets make it to
    # the tproxy delivery step.
    networking.firewall.extraReversePathFilterRules = mkIf hasOutput ''
      iifname "lo" meta mark ${toString cfg.mark} accept
    '';
  };
}
