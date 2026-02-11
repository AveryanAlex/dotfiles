let
  name = "nextcloud";
in
{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/db 700 100999 100999 - -"
    "d /persist/${name}/redis 700 100999 100999 - -"
    "d /persist/${name}/config 700 1000 1000 - -"
    "d /home/alex/tank/nextcloud 700 1000 1000 - -"
  ];

  age.secrets."${name}-db" = {
    file = ./db.age;
  };

  age.secrets."${name}-admin" = {
    file = ./admin.age;
  };

  services.nginx.virtualHosts."cloud.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.90.88.2:80";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_headers_hash_bucket_size 64;
        proxy_headers_hash_max_size 512;
        client_max_body_size 16G;
      '';
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        "${name}-db" = {
          containerConfig = {
            image = "docker.io/library/mariadb:12";
            autoUpdate = "registry";
            networks = [ networks.${name}.ref ];
            ip = "10.90.88.3";
            volumes = [ "/persist/${name}/db:/var/lib/mysql" ];
            environments = {
              MYSQL_DATABASE = name;
              MYSQL_USER = name;
            };
            environmentFiles = [ config.age.secrets."${name}-db".path ];
            exec = "--transaction-isolation=READ-COMMITTED --binlog-format=ROW";
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
          serviceConfig = {
            MemoryMax = "4G";
          };
        };

        "${name}-redis" = {
          containerConfig = {
            image = "docker.io/valkey/valkey:8";
            autoUpdate = "registry";
            networks = [ networks.${name}.ref ];
            ip = "10.90.88.4";
            volumes = [ "/persist/${name}/redis:/data" ];
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
          serviceConfig = {
            MemoryMax = "2G";
          };
        };

        "${name}-app" = {
          containerConfig = {
            image = "lscr.io/linuxserver/nextcloud:latest";
            autoUpdate = "registry";
            networks = [ networks.${name}.ref ];
            ip = "10.90.88.2";
            volumes = [
              "/persist/${name}/config:/config"
              "/home/alex/tank/nextcloud:/data"
              "/home/alex/tank:/tank"
            ];
            environments = {
              PUID = "1000";
              PGID = "1000";
              TZ = "Europe/Moscow";
              MYSQL_HOST = "${name}-db";
              MYSQL_DATABASE = name;
              MYSQL_USER = name;
              REDIS_HOST = "${name}-redis";
              NEXTCLOUD_TRUSTED_DOMAINS = "cloud.averyan.ru";
            };
            environmentFiles = [ config.age.secrets."${name}-admin".path ];
            gidMaps = [
              "0:100000:1000"
              "1000:1000:1"
              "1001:101001:98999"
            ];
            uidMaps = [
              "0:100000:1000"
              "1000:1000:1"
              "1001:101001:98999"
            ];
          };
          unitConfig = rec {
            Requires = [
              "${name}-db.service"
              "${name}-redis.service"
            ];
            After = Requires;
          };
          serviceConfig = {
            MemoryMax = "8G";
          };
        };
      };

      networks = {
        ${name}.networkConfig = {
          subnets = [ "10.90.88.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
      };
    };
}
