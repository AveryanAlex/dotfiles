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
      proxyPass = "http://127.0.0.1:8562";
      proxyWebsockets = true;
    };
  };

  age.secrets."${name}" = {
    file = ./wakapi.age;
    mode = "600";
    owner = "alex";
  };

  hm.services.podman = {
    networks.${name} = { };

    containers."${name}-server" = {
      image = "ghcr.io/muety/wakapi:latest";
      autoUpdate = "registry";
      environmentFile = [ config.age.secrets."${name}".path ];
      environment = {
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
      volumes = [ "/persist/${name}/data:/data" ];
      ports = [ "127.0.0.1:8562:3000" ];
      network = [ name ];
      extraConfig = {
        Unit = rec {
          Requires = [
            "podman-${name}-db.service"
          ];
          After = Requires;
          X-SwitchMethod = "restart";
        };
        Container = {
          GIDMap = "0:1:100000";
          UIDMap = "0:1:100000";
        };
        Service = {
          MemoryMax = "2G";
        };
      };
    };

    containers."${name}-db" = {
      image = "docker.io/postgres:17";
      autoUpdate = "registry";
      environment = {
        POSTGRES_USER = "wakapi";
        POSTGRES_PASSWORD = "wakapi";
        POSTGRES_DB = "wakapi";
      };
      volumes = [ "/persist/${name}/db:/var/lib/postgresql/data" ];
      network = [ name ];
      extraConfig = {
        Unit.X-SwitchMethod = "restart";
        Container = {
          GIDMap = "0:1:100000";
          UIDMap = "0:1:100000";
        };
        Service = {
          MemoryMax = "2G";
        };
      };
    };
  };
}
