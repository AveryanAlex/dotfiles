let
  name = "prowlarr";
in
{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/config 700 1000 100 - -"
  ];

  services.nginx.virtualHosts."prowlarr.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.90.93.2:9696";
      proxyWebsockets = true;
    };
  };

  xrayNat.interfaces = [ "pme-${name}" ];

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        ${name} = {
          containerConfig = {
            image = "lscr.io/linuxserver/prowlarr:latest";
            autoUpdate = "registry";
            networks = [ networks.${name}.ref ];
            ip = "10.90.93.2";
            volumes = [ "/persist/${name}/config:/config" ];
            environments = {
              PUID = "1000";
              PGID = "100";
              TZ = "Europe/Moscow";
            };
            # container gid 100 -> host 100 so PGID=100 matches your group
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
            MemoryMax = "1G";
          };
        };
      };

      networks = {
        ${name}.networkConfig = {
          subnets = [ "10.90.93.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
      };
    };

  networking.firewall.interfaces."pme-${name}".allowedTCPPorts = [
    8173 # qbittorrent
  ];
}
