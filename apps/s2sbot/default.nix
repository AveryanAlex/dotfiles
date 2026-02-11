{ config, ... }:
let
  name = "s2sbot";
in
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/db 700 100999 100999 - -"
  ];

  age.secrets."${name}-bot" = {
    file = ./bot.age;
  };

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
            ip = "10.90.85.3";
            volumes = [ "/persist/${name}/db:/var/lib/postgresql/data" ];
            environments = {
              POSTGRES_USER = name;
              POSTGRES_PASSWORD = name;
              POSTGRES_DB = name;
            };
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
        };

        ${name} = {
          containerConfig = {
            image = "ghcr.io/averyanalex/mirage_tgbot:main";
            autoUpdate = "registry";
            networks = [ networks.${name}.ref ];
            ip = "10.90.85.2";
            environments = {
              DATABASE_URL = "postgresql://${name}:${name}@${name}-db:5432/${name}";
              TZ = "Europe/Moscow";
            };
            environmentFiles = [ config.age.secrets."${name}-bot".path ];
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
          unitConfig = rec {
            Requires = [ "${name}-db.service" ];
            After = Requires;
          };
          serviceConfig = {
            Environment = [ "REGISTRY_AUTH_FILE=${config.environment.sessionVariables.REGISTRY_AUTH_FILE}" ];
          };
        };
      };

      networks = {
        ${name}.networkConfig = {
          subnets = [ "10.90.85.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
      };
    };
}
