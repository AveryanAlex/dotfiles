{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.networking.firewall;
  nft-cfg = config.networking.nft-firewall;

  defaultInterface = {
    default = mapAttrs (name: value: cfg.${name}) commonOptions;
  };
  allInterfaces = defaultInterface // cfg.interfaces;

  commonOptions = {
    allowedTCPPorts = mkOption {
      type = types.listOf types.port;
      default = [ ];
      apply = canonicalizePortList;
      example = [
        22
        80
      ];
      description = lib.mdDoc ''
        List of TCP ports on which incoming connections are
        accepted.
      '';
    };

    allowedTCPPortRanges = mkOption {
      type = types.listOf (types.attrsOf types.port);
      default = [ ];
      example = [
        {
          from = 8999;
          to = 9003;
        }
      ];
      description = lib.mdDoc ''
        A range of TCP ports on which incoming connections are
        accepted.
      '';
    };

    allowedUDPPorts = mkOption {
      type = types.listOf types.port;
      default = [ ];
      apply = canonicalizePortList;
      example = [ 53 ];
      description = lib.mdDoc ''
        List of open UDP ports.
      '';
    };

    allowedUDPPortRanges = mkOption {
      type = types.listOf (types.attrsOf types.port);
      default = [ ];
      example = [
        {
          from = 60000;
          to = 61000;
        }
      ];
      description = lib.mdDoc ''
        Range of open UDP ports.
      '';
    };
  };
in
{
  options = {
    networking.nft-firewall = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc "Whether to enable the nftables-based firewall.";
      };

      extraFilterOutputRules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ ];
        description = lib.mdDoc "Additional rules in filter output chain.";
      };

      extraFilterInputRules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "tcp dport 80 iifname eth0 counter accept" ];
        description = lib.mdDoc "Additional rules in input chain.";
      };

      extraFilterForwardRules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "iifname lan0 oifname wan0 counter accept" ];
        description = lib.mdDoc "Additional rules in forward chain.";
      };

      extraMangleOutputRules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ ];
        description = lib.mdDoc "Additional rules in mangle output chain.";
      };

      extraNatPreroutingRules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ ];
        description = lib.mdDoc "Additional rules in prerouting chain.";
      };

      extraNatPostroutingRules = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ ];
        description = lib.mdDoc "Additional rules in postrouting chain.";
      };
    };
  };

  config.networking = mkIf nft-cfg.enable {
    firewall.enable = false;
    nat.enable = false;

    nftables.enable = true;

    nftables.ruleset = ''
      table inet filter {
        chain output {
          type filter hook output priority 100;

          ${concatStringsSep "\n" nft-cfg.extraFilterOutputRules}

          accept
        }

        chain input {
          type filter hook input priority 0;

          # Accept all traffic on the trusted interfaces.
          ${flip concatMapStrings (cfg.trustedInterfaces ++ [ "lo" ]) (iface: ''
            iifname ${iface} accept
          '')}

          # Accept packets from established or related connections.
          ct state { established, related } accept

          # Accept connections to the allowed TCP ports.
          ${concatStrings (
            mapAttrsToList (
              iface: cfg:
              concatMapStrings (port: ''
                tcp dport ${toString port} ${optionalString (iface != "default") "iifname ${iface}"} accept
              '') cfg.allowedTCPPorts
            ) allInterfaces
          )}

          # Accept connections to the allowed TCP port ranges.
          ${concatStrings (
            mapAttrsToList (
              iface: cfg:
              concatMapStrings (
                rangeAttr:
                let
                  range = toString rangeAttr.from + "-" + toString rangeAttr.to;
                in
                ''
                  tcp dport ${range} ${optionalString (iface != "default") "iifname ${iface}"} accept
                ''
              ) cfg.allowedTCPPortRanges
            ) allInterfaces
          )}

          # Accept packets on the allowed UDP ports.
          ${concatStrings (
            mapAttrsToList (
              iface: cfg:
              concatMapStrings (port: ''
                udp dport ${toString port} ${optionalString (iface != "default") "iifname ${iface}"} accept
              '') cfg.allowedUDPPorts
            ) allInterfaces
          )}

          # Accept connections to the allowed UDP port ranges.
          ${concatStrings (
            mapAttrsToList (
              iface: cfg:
              concatMapStrings (
                rangeAttr:
                let
                  range = toString rangeAttr.from + "-" + toString rangeAttr.to;
                in
                ''
                  udp dport ${range} ${optionalString (iface != "default") "iifname ${iface}"} accept
                ''
              ) cfg.allowedUDPPortRanges
            ) allInterfaces
          )}

          # Optionally respond to ICMP pings.
          ${optionalString cfg.allowPing ''
            icmp type echo-request ${
              optionalString (cfg.pingLimit != null) "limit rate ${cfg.pingLimit} "
            }accept
          ''}
          ${optionalString (cfg.allowPing && config.networking.enableIPv6) ''
            icmpv6 type echo-request ${
              optionalString (cfg.pingLimit != null) "limit rate ${cfg.pingLimit} "
            }accept
          ''}

          icmp type {echo-reply, destination-unreachable, source-quench, redirect, time-exceeded, parameter-problem, timestamp-request, timestamp-reply, info-request, info-reply, address-mask-request, address-mask-reply, router-advertisement, router-solicitation} accept
          icmpv6 type {destination-unreachable, packet-too-big, time-exceeded, echo-reply, mld-listener-query, mld-listener-report, mld-listener-reduction, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert, nd-redirect, parameter-problem, router-renumbering} accept

          ${concatStringsSep "\n" nft-cfg.extraFilterInputRules}

          counter drop
        }

        chain forward {
          type filter hook forward priority 0;

          ct status dnat counter accept comment "allow dnat forwarding"

          ${concatStringsSep "\n" nft-cfg.extraFilterForwardRules}

          counter drop
        }
      }

      table inet mangle {
        chain output {
          type route hook output priority mangle;

          ${concatStringsSep "\n" nft-cfg.extraMangleOutputRules}
        }
      }

      table ip nat {
        chain prerouting {
          type nat hook prerouting priority dstnat; policy accept;

          ${concatStringsSep "\n" nft-cfg.extraNatPreroutingRules}
        }

        chain postrouting {
          type nat hook postrouting priority srcnat; policy accept;

          ${concatStringsSep "\n" nft-cfg.extraNatPostroutingRules}
        }
      }
    '';
  };
}
