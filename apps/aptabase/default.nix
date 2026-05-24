let
  name = "aptabase";
in
{ config, ... }:
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/db 700 100999 100999 - -"
    "d /persist/${name}/clickhouse 700 100101 100101 - -"
    "d /persist/${name}/clickhouse-logs 700 100101 100101 - -"
    "d /persist/${name}/data-protection 700 100000 100000 - -"
  ];

  age.secrets = {
    "${name}-app".file = ./app.age;
    "${name}-clickhouse".file = ./clickhouse.age;
    "${name}-db".file = ./db.age;
  };

  services.nginx.virtualHosts."stats.averylex.dev" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.90.98.2:8080";
      proxyWebsockets = true;
    };
  };

  security.acme.certs."stats.averylex.dev".dnsProvider = null;

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.${name}.networkConfig = {
        subnets = [ "10.90.98.0/24" ];
        podmanArgs = [ "--interface-name=pme-${name}" ];
      };

      containers = {
        "${name}-db" = {
          containerConfig = {
            image = "docker.io/library/postgres:15";
            autoUpdate = "registry";
            memory = "2g";
            networks = [ networks.${name}.ref ];
            ip = "10.90.98.3";
            volumes = [ "/persist/${name}/db:/var/lib/postgresql/data" ];
            environments = {
              POSTGRES_DB = name;
              POSTGRES_USER = name;
            };
            environmentFiles = [ config.age.secrets."${name}-db".path ];
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
        };

        "${name}-clickhouse" = {
          containerConfig = {
            image = "docker.io/clickhouse/clickhouse-server:23.8.4.69-alpine";
            autoUpdate = "registry";
            memory = "4g";
            networks = [ networks.${name}.ref ];
            ip = "10.90.98.4";
            volumes = [
              "/persist/${name}/clickhouse:/var/lib/clickhouse"
              "/persist/${name}/clickhouse-logs:/var/log/clickhouse-server"
            ];
            environments = {
              CLICKHOUSE_USER = name;
            };
            environmentFiles = [ config.age.secrets."${name}-clickhouse".path ];
            ulimits = [ "nofile=262144:262144" ];
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
        };

        "${name}-app" = {
          containerConfig = {
            image = "ghcr.io/aptabase/aptabase:main";
            autoUpdate = "registry";
            memory = "2g";
            networks = [ networks.${name}.ref ];
            ip = "10.90.98.2";
            environments = {
              BASE_URL = "https://stats.averylex.dev";
              REGION = "SH";
            };
            environmentFiles = [ config.age.secrets."${name}-app".path ];
            volumes = [ "/persist/${name}/data-protection:/root/.aspnet/DataProtection-Keys" ];
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
          unitConfig = rec {
            Requires = [
              "${name}-clickhouse.service"
              "${name}-db.service"
            ];
            After = Requires;
          };
        };
      };
    };
}
