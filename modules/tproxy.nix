# Transparent proxy module
# Provides traffic redirection for both forwarded and local traffic using nftables
{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.networking.tproxy;

  # Default protocols and ports for HTTP/HTTPS traffic
  defaultTcpPorts = [
    80
    443
  ];
  defaultUdpPorts = [ 443 ];

  # Rules to skip private/local addresses
  skipPrivateRules = ''
    ip daddr { 0.0.0.0/8, 10.0.0.0/8, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 } return
    ip6 daddr { ::1/128, fc00::/7, fe80::/10, ff00::/8 } return
  '';

  # Build redirect rules for specific ports
  mkRedirectRules =
    {
      tcpPorts,
      udpPorts,
      mark,
      port,
    }:
    let
      tcpPortsStr = concatStringsSep ", " (map toString tcpPorts);
      udpPortsStr = concatStringsSep ", " (map toString udpPorts);
    in
    ''
      ${optionalString (
        tcpPorts != [ ]
      ) "tcp dport { ${tcpPortsStr} } meta mark != ${toString mark} redirect to :${toString port}"}
      ${optionalString (
        udpPorts != [ ]
      ) "udp dport { ${udpPortsStr} } meta mark != ${toString mark} redirect to :${toString port}"}
    '';

  # Full rules including skipPrivate (for output chain)
  mkRules =
    {
      tcpPorts,
      udpPorts,
      mark,
      port,
    }:
    ''
      ${skipPrivateRules}
      ${mkRedirectRules {
        inherit
          tcpPorts
          udpPorts
          mark
          port
          ;
      }}
    '';

  # Forward rules with interface filter:
  # 1. Skip traffic not from needed interfaces
  # 2. Skip traffic to localnet
  # 3. Redirect matched ports
  mkForwardRules =
    {
      interfaces,
      tcpPorts,
      udpPorts,
      mark,
      port,
    }:
    let
      ifacesStr = concatStringsSep ", " interfaces;
      tcpPortsStr = concatStringsSep ", " (map toString tcpPorts);
      udpPortsStr = concatStringsSep ", " (map toString udpPorts);
    in
    ''
      iifname != { ${ifacesStr} } return
      ${skipPrivateRules}
      ${optionalString (
        tcpPorts != [ ]
      ) "tcp dport { ${tcpPortsStr} } meta mark != ${toString mark} redirect to :${toString port}"}
      ${optionalString (
        udpPorts != [ ]
      ) "udp dport { ${udpPortsStr} } meta mark != ${toString mark} redirect to :${toString port}"}
    '';
in
{
  options.networking.tproxy = {
    enable = mkEnableOption "transparent proxy";

    port = mkOption {
      type = types.port;
      default = 18298;
      description = "Port the transparent proxy listens on for connections.";
    };

    mark = mkOption {
      type = types.int;
      default = 18298;
      description = "Firewall mark used to avoid loops in traffic redirection.";
    };

    # Default protocols/ports for all traffic types
    defaultTcpPorts = mkOption {
      type = types.listOf types.port;
      default = defaultTcpPorts;
      description = "Default TCP ports to redirect through proxy (used when not overridden).";
    };

    defaultUdpPorts = mkOption {
      type = types.listOf types.port;
      default = defaultUdpPorts;
      description = "Default UDP ports to redirect through proxy (used when not overridden).";
    };

    # Output proxy (this host's traffic)
    output = {
      enable = mkEnableOption "transparent proxy for this host's outbound traffic";

      tcpPorts = mkOption {
        type = types.listOf types.port;
        default = cfg.defaultTcpPorts;
        description = "TCP ports to redirect from this host through proxy.";
      };

      udpPorts = mkOption {
        type = types.listOf types.port;
        default = cfg.defaultUdpPorts;
        description = "UDP ports to redirect from this host through proxy.";
      };
    };

    # Forward proxy (traffic from other interfaces/containers)
    forward = {
      interfaces = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "pme-lidarr" ];
        description = ''
          Interface names whose traffic is redirected through transparent proxy.
          Use podman network interface names to send container traffic via proxy.
        '';
      };

      tcpPorts = mkOption {
        type = types.listOf types.port;
        default = cfg.defaultTcpPorts;
        description = "TCP ports to redirect from forwarded interfaces through proxy.";
      };

      udpPorts = mkOption {
        type = types.listOf types.port;
        default = cfg.defaultUdpPorts;
        description = "UDP ports to redirect from forwarded interfaces through proxy.";
      };
    };
  };

  config = mkIf cfg.enable {
    networking.nftables.tables.tproxy-nat = {
      family = "inet";
      content =
        let
          hasForward = cfg.forward.interfaces != [ ];
          hasOutput = cfg.output.enable;
        in
        ''
          ${optionalString hasForward ''
            chain pre {
              type nat hook prerouting priority dstnat - 10; policy accept;
              ${mkForwardRules {
                interfaces = cfg.forward.interfaces;
                tcpPorts = cfg.forward.tcpPorts;
                udpPorts = cfg.forward.udpPorts;
                mark = cfg.mark;
                port = cfg.port;
              }}
            }
          ''}
          ${optionalString hasOutput ''
            chain out {
              type nat hook output priority mangle - 10; policy accept;
              ${mkRules {
                tcpPorts = cfg.output.tcpPorts;
                udpPorts = cfg.output.udpPorts;
                mark = cfg.mark;
                port = cfg.port;
              }}
            }
          ''}
        '';
    };

    # Allow proxy port on forwarded interfaces
    networking.firewall.interfaces = mkMerge (
      map (iface: { ${iface}.allowedTCPPorts = [ cfg.port ]; }) cfg.forward.interfaces
    );
  };
}
