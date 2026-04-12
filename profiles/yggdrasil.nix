{
  config,
  lib,
  ...
}:
{
  # Yggdrasil's 0200::/7 subnet must never be proxied — traffic to mesh
  # peers is overlay-internal and sending it through mihomo would either
  # fail or add pointless latency.
  networking.tproxy.extraBypassCIDRs.ipv6 = [ "0200::/7" ];

  services.yggdrasil = {
    enable = true;
    openMulticastPort = true;
    settings = {
      Listen = [
        "tls://[::]:8362"
        "tcp://[::]:8363"
        "quic://[::]:8364"
      ];
      Peers = lib.mkIf (config.networking.hostName != "whale") [
        "quic://ygg-msk-1.averyan.ru:8364"
        "tls://ygg-msk-1.averyan.ru:8363"
      ];
      IfName = "ygg0";
      MulticastInterfaces = [
        {
          Port = 9217;
        }
      ];
      NodeInfo = {
        name = "${config.networking.hostName}.averyanalex";
      };
    };
    denyDhcpcdInterfaces = [ "ygg0" ];
  };

  systemd.services.yggdrasil = {
    serviceConfig = {
      MemoryMax = "1G";
    };
  };

  networking.firewall.allowedTCPPorts = [
    8362
    8363
    8364
    9217
  ];
  networking.firewall.allowedUDPPorts = [ 8364 ];
}
