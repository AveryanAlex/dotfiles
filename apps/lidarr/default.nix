let
  name = "lidarr";
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
    container = "lidarr";
    databases = [
      {
        host = "/persist/lidarr/config/lidarr.db";
        path = "/config/lidarr.db";
        target = "lidarr.db";
      }
    ];
  };
in
{
  services.rusticBackup.jobs.lidarr = {
    paths = [ "/persist/lidarr/config" ];
    exclude = sqliteBackup.exclude ++ [
      "/persist/lidarr/config/logs"
      "/persist/lidarr/config/logs.db"
      "/persist/lidarr/config/logs.db-wal"
      "/persist/lidarr/config/logs.db-shm"
      "/persist/lidarr/config/logs.db-journal"
      "/persist/lidarr/config/Backups"
    ];
    requiresUnits = [ "lidarr.service" ];
    runtimePackages = [ config.virtualisation.podman.package ];
    backupStaging = true;
    inherit (sqliteBackup) prepareScript;
  };

  systemd.slices.${sliceName}.description = "Lidarr application services";

  systemd.tmpfiles.rules = [
    "d /persist/${name}/config 700 1000 100 - -"
  ];

  services.nginx.virtualHosts."lidarr.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.90.90.2:8686";
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
            image = "ghcr.io/linuxserver-labs/prarr:lidarr-plugins";
            autoUpdate = "registry";
            memory = "8g";
            networks = [ networks.${name}.ref ];
            ip = "10.90.90.2";
            volumes = [
              sqliteBackup.volume
              "/persist/${name}/config:/config"
              "/home/alex/tank/hot:/home/alex/tank/hot"
              # "/home/alex/tank/hot:/data"
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
            subnets = [ "10.90.90.0/24" ];
            podmanArgs = [ "--interface-name=pme-${name}" ];
          };
          serviceConfig.Slice = appServiceConfig.Slice;
        };
      };
    };

  networking.firewall.extraForwardRules = ''
    iifname pme-${name} oifname pme-slskd accept
    iifname pme-${name} oifname pme-qbit accept
  '';
}
