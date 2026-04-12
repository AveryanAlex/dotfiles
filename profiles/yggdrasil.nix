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

  # Yggdrasil peers on arbitrary ports (including 80/443) must bypass tproxy.
  # Pin yggdrasil to a static UID so `meta skuid` works reliably in nftables
  # (DynamicUser UIDs aren't resolvable at rule-load time and cgroup matching
  # is chicken-and-egg at boot). The skip fires in the output chain before
  # the mark-set step.
  networking.tproxy.defaults.skipUsers = [ "yggdrasil" ];

  systemd.services.yggdrasil.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "yggdrasil";
    Group = "yggdrasil";
  };

  users.users.yggdrasil = {
    isSystemUser = true;
    group = "yggdrasil";
    uid = 862;
  };
  users.groups.yggdrasil.gid = 862;

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
