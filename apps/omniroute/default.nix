let
  name = "omniroute";
in
{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/data 700 100000 100000 - -"
  ];

  services.nginx.virtualHosts."omniroute.neutrino.su" = {
    useACMEHost = "neutrino.su";
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://10.90.97.2:20128";
      proxyWebsockets = true;

      extraConfig = ''
        proxy_connect_timeout 1h;
        proxy_send_timeout 1h;
        proxy_read_timeout 1h;
        send_timeout 1h;
        proxy_buffering off;
      '';
    };
  };

  age.secrets.${name}.file = ./main.age;

  networking.tproxy.forward."pme-${name}" = { };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers.${name} = {
        containerConfig = {
          image = "ghcr.io/averyanalex/omniroute:latest";
          autoUpdate = "registry";
          memory = "5g";
          networks = [ networks.${name}.ref ];
          ip = "10.90.97.2";
          volumes = [ "/persist/${name}/data:/app/data" ];
          environments = {
            AUTH_COOKIE_SECURE = "true";
            DATA_DIR = "/app/data";
            HOSTNAME = "0.0.0.0";
            NEXT_PUBLIC_BASE_URL = "https://omniroute.neutrino.su";
            NODE_OPTIONS = "--max-old-space-size=4096";
            REQUIRE_API_KEY = "true";
            TZ = "Europe/Moscow";
          };
          environmentFiles = [ config.age.secrets.${name}.path ];
          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];
        };
      };

      networks.${name}.networkConfig = {
        subnets = [ "10.90.97.0/24" ];
        podmanArgs = [ "--interface-name=pme-${name}" ];
      };
    };
}
