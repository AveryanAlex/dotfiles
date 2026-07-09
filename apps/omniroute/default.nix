let
  name = "omniroute";
in
{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/data 700 101000 101000 - -"
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

  networking.firewall.interfaces."pme-${name}".allowedTCPPorts = [
    8080 # http proxy
  ];

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers.${name} = {
        containerConfig = {
          image = "docker.io/diegosouzapw/omniroute:latest"; # "ghcr.io/averyanalex/omniroute:latest";
          autoUpdate = "registry";
          memory = "5g";
          networks = [ networks.${name}.ref ];
          ip = "10.90.97.2";
          volumes = [ "/persist/${name}/data:/app/data" ];
          environments = {
            AUTH_COOKIE_SECURE = "true";
            # Main request/history analytics
            CALL_LOG_RETENTION_DAYS = "365000";
            CALL_LOG_MAX_ENTRIES = "2147483647";
            CALL_LOGS_TABLE_MAX_ROWS = "2147483647";
            DATA_DIR = "/app/data";
            HOSTNAME = "0.0.0.0";
            NEXT_PUBLIC_BASE_URL = "https://omniroute.neutrino.su";
            NODE_OPTIONS = "--max-old-space-size=4096";
            REQUIRE_API_KEY = "true";
            TZ = "Europe/Moscow";
            # App/audit/proxy logs
            APP_LOG_RETENTION_DAYS = "365000";
            APP_LOG_MAX_FILES = "2147483647";
            PROXY_LOGS_TABLE_MAX_ROWS = "2147483647";
            # DB backup cleanup
            DB_BACKUP_RETENTION_DAYS = "0";
            DB_BACKUP_MAX_FILES = "2147483647";
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
