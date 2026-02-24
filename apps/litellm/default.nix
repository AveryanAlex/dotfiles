let
  name = "litellm";
in
{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/db 700 100999 100999 - -"
  ];

  services.nginx.virtualHosts = {
    "litellm.averyan.ru" = {
      useACMEHost = "averyan.ru";
      forceSSL = true;

      locations."/" = {
        proxyPass = "http://10.90.95.2:4000";
        proxyWebsockets = true;

        extraConfig = ''
          proxy_connect_timeout 300s;
          proxy_send_timeout 300s;
          proxy_read_timeout 300s;
          send_timeout 300s;
          proxy_buffering off;
        '';
      };
    };
  };

  age.secrets.${name}.file = ./main.age;

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.${name}.networkConfig = {
        subnets = [ "10.90.95.0/24" ];
        podmanArgs = [ "--interface-name=pme-${name}" ];
      };

      containers."${name}-db".containerConfig = {
        image = "docker.io/library/postgres:17";
        autoUpdate = "registry";
        networks = [ networks.${name}.ref ];
        ip = "10.90.95.3";
        environments = {
          POSTGRES_DB = name;
          POSTGRES_USER = name;
          POSTGRES_PASSWORD = name;
        };
        volumes = [ "/persist/${name}/db:/var/lib/postgresql/data" ];
        gidMaps = [ "0:100000:100000" ];
        uidMaps = [ "0:100000:100000" ];
      };

      containers."${name}-app" = {
        containerConfig = {
          image = "ghcr.io/berriai/litellm-database:main-latest";
          autoUpdate = "registry";
          networks = [ networks.${name}.ref ];
          ip = "10.90.95.2";
          environments = {
            DATABASE_URL = "postgresql://${name}:${name}@${name}-db:5432/${name}";
            STORE_MODEL_IN_DB = "True";
          };
          environmentFiles = [ config.age.secrets.${name}.path ];
          volumes = [
            "${./config.yml}:/app/config.yaml:ro"
          ];
          exec = "--config=/app/config.yaml";
          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];
        };
        unitConfig = rec {
          Requires = [
            "${name}-db.service"
          ];
          After = Requires;
        };
      };
    };
}
