let
  name = "wakapi";
in
{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/data 700 101000 101000 - -"
    "d /persist/${name}/db 700 100999 100999 - -"
  ];

  services.nginx.virtualHosts."waka.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.90.86.2:3000";
      proxyWebsockets = true;
    };
  };

  age.secrets."${name}".file = ./wakapi.age;

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        "${name}-db" = {
          containerConfig = {
            image = "docker.io/library/postgres:17";
            autoUpdate = "registry";
            networks = [ networks.${name}.ref ];
            ip = "10.90.86.3";
            volumes = [ "/persist/${name}/db:/var/lib/postgresql/data" ];
            environments = {
              POSTGRES_USER = "wakapi";
              POSTGRES_PASSWORD = "wakapi";
              POSTGRES_DB = "wakapi";
            };
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
        };

        "${name}-server" = {
          containerConfig = {
            image = "ghcr.io/muety/wakapi:latest";
            autoUpdate = "registry";
            networks = [ networks.${name}.ref ];
            ip = "10.90.86.2";
            volumes = [ "/persist/${name}/data:/data" ];
            environments = {
              WAKAPI_DB_TYPE = "postgres";
              WAKAPI_DB_HOST = "${name}-db";
              WAKAPI_DB_PORT = "5432";
              WAKAPI_DB_USER = "wakapi";
              WAKAPI_DB_PASSWORD = "wakapi";
              WAKAPI_DB_NAME = "wakapi";
              WAKAPI_LEADERBOARD_ENABLED = "false";
              WAKAPI_ALLOW_SIGNUP = "true";
              WAKAPI_PUBLIC_URL = "https://waka.averyan.ru";
            };
            environmentFiles = [ config.age.secrets."${name}".path ];
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
          unitConfig = rec {
            Requires = [ "${name}-db.service" ];
            After = Requires;
          };
        };
      };

      networks = {
        ${name}.networkConfig = {
          subnets = [ "10.90.86.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
      };
    };
}
