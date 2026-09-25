let
  name = "slskd";
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
    container = "slskd";
    databases = [
      {
        host = "/persist/slskd/data/transfers.db";
        path = "/app/data/transfers.db";
        target = "data/transfers.db";
      }
      {
        host = "/persist/slskd/data/events.db";
        path = "/app/data/events.db";
        target = "data/events.db";
      }
      {
        host = "/persist/slskd/data/messaging.db";
        path = "/app/data/messaging.db";
        target = "data/messaging.db";
      }
      {
        host = "/persist/slskd/data/search.db";
        path = "/app/data/search.db";
        target = "data/search.db";
      }
    ];
  };
in
{
  services.rusticBackup.jobs.slskd = {
    paths = [ "/persist/slskd" ];
    exclude = sqliteBackup.exclude ++ [
      "/persist/slskd/logs"
      "/persist/slskd/downloads"
      "/persist/slskd/incomplete"
      "/persist/slskd/data/backups"
      "/persist/slskd/data/shares.local.bak.db"
    ];
    requiresUnits = [ "slskd.service" ];
    runtimePackages = [ config.virtualisation.podman.package ];
    backupStaging = true;
    inherit (sqliteBackup) prepareScript;
  };

  systemd.slices.${sliceName}.description = "slskd application services";

  systemd.tmpfiles.rules = [
    "d /persist/${name} 700 1000 100 - -"
  ];

  services.nginx.virtualHosts."slskd.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://10.90.91.2:5030";
      proxyWebsockets = true;
    };
  };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        ${name} = {
          containerConfig = {
            image = "docker.io/slskd/slskd:latest";
            autoUpdate = "registry";
            memory = "2g";
            networks = [ networks.${name}.ref ];
            ip = "10.90.91.2";
            volumes = [
              sqliteBackup.volume
              "/persist/${name}:/app"
              "/home/alex/tank/hot/Downloads/Soulseek:/home/alex/tank/hot/Downloads/Soulseek"
              "/home/alex/tank/hot/Music:/home/alex/tank/hot/Music"
            ];
            environments = {
              SLSKD_REMOTE_CONFIGURATION = "true";
              SLSKD_SHARED_DIR = "/home/alex/tank/hot/Music";
              # TZ = "Europe/Moscow";
            };
            user = "1000:100";
            # container uid 1000 -> host 1000, gid 100 -> host 100
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
            subnets = [ "10.90.91.0/24" ];
            podmanArgs = [ "--interface-name=pme-${name}" ];
          };
          serviceConfig.Slice = appServiceConfig.Slice;
        };
      };
    };

  networking.nat.forwardPorts =
    let
      common = {
        destination = "10.90.91.2:50300";
        sourcePort = 50300;
        loopbackIPs = [ "95.165.105.90" ];
      };
    in
    [
      (common // { proto = "tcp"; })
      (common // { proto = "udp"; })
    ];
}
