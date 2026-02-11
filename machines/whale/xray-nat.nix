# Redirect traffic to xray transparent proxy (no port publish).
# xrayNat.interfaces = forwarded traffic from those interfaces; xrayNat.proxyOwnTraffic = this host's traffic.
{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.xrayNat;
  ifacesStr = concatStringsSep ", " cfg.interfaces;
  skipPrivateRules = ''
    ip daddr { 0.0.0.0/8, 10.0.0.0/8, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 } return
    ip6 daddr { ::1/128, fc00::/7, fe80::/10, ff00::/8 } return
  '';
  # Skip private/local; redirect tcp 80/443 and udp 443 from listed interfaces to xray port
  preroutingRules = ''
    ${skipPrivateRules}
    iifname { ${ifacesStr} } tcp dport { 80, 443 } meta mark != ${toString cfg.port} redirect to :${toString cfg.port}
    iifname { ${ifacesStr} } udp dport { 443 } meta mark != ${toString cfg.port} redirect to :${toString cfg.port}
  '';
  # Redirect this host's outbound tcp 80/443, udp 443 to xray
  outputRules = ''
    ${skipPrivateRules}
    tcp dport { 80, 443 } meta mark != ${toString cfg.port} redirect to :${toString cfg.port}
    udp dport { 443 } meta mark != ${toString cfg.port} redirect to :${toString cfg.port}
  '';
in
{
  options.xrayNat = {
    interfaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "pme-hass" ];
      description = lib.mdDoc ''
        Interface names whose traffic (tcp 80/443, udp 443) is redirected to xray transparent proxy.
        Use podman network interface names (e.g. pme-hass) to send container traffic via VPN.
      '';
    };
    port = mkOption {
      type = types.port;
      default = 18298;
      description = lib.mdDoc "Port xray listens on for transparent proxy (redirect target).";
    };
    proxyOwnTraffic = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Redirect this host's outbound tcp 80/443 and udp 443 to xray (output hook).
        Enable when you want local traffic to go through the VPN.
      '';
    };
  };

  config = mkIf (cfg.interfaces != [ ] || cfg.proxyOwnTraffic) {
    networking.nftables.tables.xray-nat = {
      family = "inet";
      content = ''
        ${optionalString (cfg.interfaces != [ ]) ''
          chain pre {
            type nat hook prerouting priority dstnat - 10; policy accept;
            ${preroutingRules}
          }
        ''}
        ${optionalString cfg.proxyOwnTraffic ''
          chain out {
            type nat hook output priority mangle - 10; policy accept;
            ${outputRules}
          }
        ''}
      '';
    };

    networking.firewall.interfaces = mkMerge (
      map (iface: { ${iface}.allowedTCPPorts = [ cfg.port ]; }) cfg.interfaces
    );
  };
}
