let
  name = "prowlarr";
  sliceName = "apps-${name}";
  appServiceConfig = {
    Slice = "${sliceName}.slice";
    RestartMode = "direct";
    RestartSec = "5s";
    TimeoutStartSec = "4min";
  };
  appUnitConfig = {
    StartLimitIntervalSec = "10min";
    StartLimitBurst = 6;
  };
in
{
  config,
  lib,
  pkgs,
  ...
}:
let
  sqliteBackup = (import ../lib/sqlite-backup.nix { inherit lib pkgs; }) {
    container = "prowlarr";
    databases = [
      {
        host = "/persist/prowlarr/config/prowlarr.db";
        path = "/config/prowlarr.db";
        target = "prowlarr.db";
      }
    ];
  };
in
{
  services.rusticBackup.jobs.prowlarr = {
    paths = [ "/persist/prowlarr/config" ];
    exclude = sqliteBackup.exclude ++ [
      "/persist/prowlarr/config/logs"
      "/persist/prowlarr/config/logs.db"
      "/persist/prowlarr/config/logs.db-wal"
      "/persist/prowlarr/config/logs.db-shm"
      "/persist/prowlarr/config/logs.db-journal"
      "/persist/prowlarr/config/Backups"
    ];
    requiresUnits = [ "prowlarr.service" ];
    runtimePackages = [ config.virtualisation.podman.package ];
    backupStaging = true;
    inherit (sqliteBackup) prepareScript;
  };

  systemd.slices.${sliceName}.description = "Prowlarr application services";

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

  networking.tproxy.forward."pme-${name}" = { };

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
            memory = "1g";
            networks = [ networks.${name}.ref ];
            ip = "10.90.93.2";
            volumes = [
              sqliteBackup.volume
              "/persist/${name}/config:/config"
            ];
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
          unitConfig = appUnitConfig;
          serviceConfig = appServiceConfig;
        };
      };

      networks = {
        ${name} = {
          networkConfig = {
            subnets = [ "10.90.93.0/24" ];
            podmanArgs = [ "--interface-name=pme-${name}" ];
          };
          serviceConfig.Slice = appServiceConfig.Slice;
        };
      };
    };

  networking.firewall.extraForwardRules = ''
    iifname pme-${name} oifname pme-qbit accept
  '';
}
