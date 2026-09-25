let
  name = "immich";
  versionTag = "v3";
  sliceName = "apps-${name}";
  uidMaps = [ "0:100000:100000" ];
  gidMaps = [ "0:100000:100000" ];
  appServiceConfig = {
    Slice = "${sliceName}.slice";
    RestartMode = "direct";
    RestartSec = "5s";
    TimeoutStartSec = "4min";
    TimeoutStopSec = "2min";
  };
  appUnitConfig = {
    StartLimitIntervalSec = "10min";
    StartLimitBurst = 6;
  };
in
{ config, pkgs, ... }:
let
  mlLogConfig = pkgs.writeText "immich-ml-log-conf.json" ''
    {
      "version": 1,
      "disable_existing_loggers": false,
      "formatters": {
        "plain": {
          "format": "[%(asctime)s] %(levelname)-8s %(message)s",
          "datefmt": "%m/%d/%y %H:%M:%S"
        }
      },
      "handlers": {
        "console": {
          "class": "logging.StreamHandler",
          "stream": "ext://sys.stdout",
          "formatter": "plain"
        }
      },
      "root": { "level": "INFO", "handlers": ["console"] },
      "loggers": {
        "gunicorn.error": { "level": "INFO", "handlers": ["console"], "propagate": false },
        "gunicorn.access": { "level": "WARNING", "handlers": ["console"], "propagate": false },
        "uvicorn": { "level": "INFO", "handlers": ["console"], "propagate": false },
        "uvicorn.access": { "level": "WARNING", "handlers": ["console"], "propagate": false }
      }
    }
  '';
in
{
  services.rusticBackup.jobs.immich = {
    paths = [
      "/home/alex/tank/Immich/library"
      "/home/alex/tank/Immich/upload"
      "/home/alex/tank/Immich/profile"
    ];
    # Start after the smaller daily jobs; allow time for the initial media upload.
    calendar = "*-*-* 06:00:00 Europe/Moscow";
    timeout = "48h";
    requiresUnits = [ "immich-database.service" ];
    runtimePackages = [ config.virtualisation.podman.package ];
    backupStaging = true;
    prepareScript = ''
      # Live backup: the database and media are not an atomic snapshot.
      podman exec --user postgres immich-database pg_dump \
        --username=postgres --no-password --format=custom --compress=0 immich \
        > "$BACKUP_STAGING_DIR/immich.dump"
      # Record actual image IDs because the server's v3 tag can move.
      podman container inspect \
        --format '{{.Name}} {{.ImageName}} {{.Image}}' \
        immich-server immich-database immich-machine-learning immich-valkey \
        > "$BACKUP_STAGING_DIR/container-images.txt"
    '';
  };

  systemd.tmpfiles.rules = [
    "d /persist/${name} 700 0 0 - -"
    "d /persist/${name}/postgres 700 100999 100999 - -"
    "d /persist/${name}/model-cache 700 100000 100000 - -"
    "d /persist/${name}/valkey 700 100999 100999 - -"
  ];

  systemd.slices.${sliceName}.description = "Immich application services";

  age.secrets."${name}-db".file = ./db.age;

  networking.tproxy.forward."pme-${name}" = { };

  services.nginx.virtualHosts."immich.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.90.100.2:2283";
      proxyWebsockets = true;
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
      commonConfig = {
        inherit uidMaps gidMaps;
        networks = [ networks.${name}.ref ];
      };
    in
    {
      networks.${name} = {
        networkConfig = {
          subnets = [ "10.90.100.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
        serviceConfig.Slice = appServiceConfig.Slice;
      };

      containers = {
        "${name}-database" = {
          containerConfig = commonConfig // {
            image = "ghcr.io/immich-app/postgres@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
            memory = "3g";
            shmSize = "128m";
            ip = "10.90.100.3";
            networkAliases = [ "database" ];
            volumes = [ "/persist/${name}/postgres:/var/lib/postgresql/data" ];
            environments = {
              POSTGRES_USER = "postgres";
              POSTGRES_DB = name;
              POSTGRES_INITDB_ARGS = "--data-checksums";
            };
            environmentFiles = [ config.age.secrets."${name}-db".path ];
            healthCmd = "/usr/local/bin/healthcheck.sh";
            healthInterval = "10s";
            healthTimeout = "10s";
            healthRetries = 5;
            healthStartPeriod = "30s";
            healthOnFailure = "kill";
            notify = "healthy";
            stopTimeout = 60;
          };
          unitConfig = appUnitConfig;
          serviceConfig = appServiceConfig;
        };

        "${name}-valkey" = {
          containerConfig = commonConfig // {
            image = "docker.io/valkey/valkey:9@sha256:4963247afc4cd33c7d3b2d2816b9f7f8eeebab148d29056c2ca4d7cbc966f2d9";
            memory = "256m";
            ip = "10.90.100.4";
            networkAliases = [ "redis" ];
            volumes = [ "/persist/${name}/valkey:/data" ];
            healthCmd = "redis-cli ping || exit 1";
            healthInterval = "30s";
            healthTimeout = "10s";
            healthRetries = 3;
            healthOnFailure = "kill";
            notify = "healthy";
            stopTimeout = 30;
          };
          unitConfig = appUnitConfig;
          serviceConfig = appServiceConfig;
        };

        "${name}-machine-learning" = {
          containerConfig = commonConfig // {
            image = "ghcr.io/immich-app/immich-machine-learning:${versionTag}";
            autoUpdate = "registry";
            memory = "6g";
            ip = "10.90.100.5";
            networkAliases = [ "immich-machine-learning" ];
            volumes = [
              "/persist/${name}/model-cache:/cache"
              "${mlLogConfig}:/usr/src/immich_ml/log_conf.json:ro"
            ];
            environments.TZ = "Europe/Moscow";
            healthCmd = "python3 healthcheck.py";
            healthInterval = "30s";
            healthTimeout = "10s";
            healthRetries = 5;
            healthStartPeriod = "60s";
            healthOnFailure = "kill";
            notify = "healthy";
            stopTimeout = 60;
          };
          unitConfig = appUnitConfig;
          serviceConfig = appServiceConfig;
        };

        "${name}-server" = {
          containerConfig = commonConfig // {
            image = "ghcr.io/immich-app/immich-server:${versionTag}";
            autoUpdate = "registry";
            memory = "8g";
            ip = "10.90.100.2";
            networkAliases = [ "immich-server" ];
            volumes = [ "/home/alex/tank/Immich:/data" ];
            environments = {
              DB_HOSTNAME = "${name}-database";
              DB_PORT = "5432";
              DB_USERNAME = "postgres";
              DB_DATABASE_NAME = name;
              REDIS_HOSTNAME = "${name}-valkey";
              REDIS_PORT = "6379";
              IMMICH_MACHINE_LEARNING_URL = "http://${name}-machine-learning:3003";
              IMMICH_MEDIA_LOCATION = "/data";
              IMMICH_TRUSTED_PROXIES = "10.90.100.1";
              TZ = "Europe/Moscow";
            };
            environmentFiles = [ config.age.secrets."${name}-db".path ];
            healthCmd = "immich-healthcheck";
            healthInterval = "30s";
            healthTimeout = "10s";
            healthRetries = 5;
            healthStartPeriod = "60s";
            healthOnFailure = "kill";
            notify = "healthy";
            stopTimeout = 60;
          };
          unitConfig = appUnitConfig // rec {
            Requires = [
              "${name}-database.service"
              "${name}-valkey.service"
            ];
            Wants = [ "${name}-machine-learning.service" ];
            After = Requires;
            RequiresMountsFor = [ "/home/alex/tank/Immich" ];
          };
          serviceConfig = appServiceConfig;
        };
      };
    };
}
