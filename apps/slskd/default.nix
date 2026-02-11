let
  name = "slskd";
in
{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name} 700 1000 100 - -"
  ];

  services.nginx.virtualHosts."slskd.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.90.91.2:5030";
      proxyWebsockets = true;
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        ${name} = {
          containerConfig = {
            image = "docker.io/slskd/slskd:latest";
            autoUpdate = "registry";
            networks = [ networks.${name}.ref ];
            ip = "10.90.91.2";
            volumes = [
              "/persist/${name}:/app"
              "/home/alex/tank/hot/Downloads/Soulseek:/home/alex/tank/hot/Downloads/Soulseek"
            ];
            environments = {
              SLSKD_REMOTE_CONFIGURATION = "true";
              # SLSKD_SHARED_DIR = "/music";
              # TZ = "Europe/Moscow";
            };
            user = "1000:100";
            # container uid 1000 -> host 1000, gid 100 -> host 100
            gidMaps = [
              "0:100000:100"
              "100:100:1"
              "101:100101:98999"
            ];
            uidMaps = [
              "0:100000:1000"
              "1000:1000:1"
              "1001:101001:98999"
            ];
          };
          serviceConfig = {
            MemoryMax = "2G";
          };
        };
      };

      networks = {
        ${name}.networkConfig = {
          subnets = [ "10.90.91.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
      };
    };

  networking.nat.forwardPorts =
    let
      common = {
        destination = "10.90.91.2:50300";
        sourcePort = 50300;
        loopbackIPs = [ "95.165.105.90" ];
      };
    in
    [
      (common // { proto = "tcp"; })
      (common // { proto = "udp"; })
    ];
}
