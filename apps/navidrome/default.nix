let
  name = "navidrome";
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
  instances = [
    "alex"
    # "ssk8q"
  ];
  instanceIP = index: "10.90.92.${toString (index + 2)}";
  # alex -> navidrome / navidrome.averyan.ru; others -> ${instance}-navidrome / ${instance}.navidrome.averyan.ru
  containerName = instance: if instance == "alex" then name else "${instance}-${name}";
  vhostName =
    instance: if instance == "alex" then "${name}.averyan.ru" else "${name}-${instance}.averyan.ru";
in
{
  config,
  lib,
  pkgs,
  ...
}:
let
  sqliteBackups = map (
    instance:
    (import ../lib/sqlite-backup.nix { inherit lib pkgs; }) {
      container = containerName instance;
      sqlite = "/usr/bin/sqlite3";
      databases = [
        {
          host = "/persist/navidrome/${instance}/navidrome.db";
          path = "/data/navidrome.db";
          target = "${instance}/navidrome.db";
        }
      ];
    }
  ) instances;
in
{
  services.rusticBackup.jobs.navidrome = {
    paths = map (instance: "/persist/navidrome/${instance}") instances;
    exclude = lib.concatMap (backup: backup.exclude) sqliteBackups ++ [
      "/persist/navidrome/*/cache"
    ];
    requiresUnits = map (instance: "${containerName instance}.service") instances;
    runtimePackages = [ config.virtualisation.podman.package ];
    backupStaging = true;
    prepareScript = lib.concatMapStringsSep "\n" (backup: backup.prepareScript) sqliteBackups;
  };

  systemd.slices.${sliceName}.description = "Navidrome application services";

  systemd.tmpfiles.rules = map (
    instance: "d /persist/${name}/${instance} 700 1000 100 - -"
  ) instances;

  services.nginx.virtualHosts = builtins.listToAttrs (
    map
      (x: {
        name = vhostName x.instance;
        value = {
          useACMEHost = "averyan.ru";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://${instanceIP x.index}:4533";
            proxyWebsockets = true;
          };
        };
      })
      (
        builtins.genList (i: {
          index = i;
          instance = builtins.elemAt instances i;
        }) (builtins.length instances)
      )
  );

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
      containerFor = index: instance: {
        containerConfig = {
          image = "docker.io/deluan/navidrome:latest";
          autoUpdate = "registry";
          memory = "1g";
          networks = [ networks.${name}.ref ];
          ip = instanceIP index;
          volumes = [
            "/persist/${name}/${instance}:/data"
            "/home/alex/tank/hot/Music:/music:ro"
          ];
          environments = {
            ND_LOGLEVEL = "info";
            ND_SCANSCHEDULE = "@every 1h";
            ND_SESSIONTIMEOUT = "24h";
            TZ = "Europe/Moscow";
          };
          user = "1000:100";
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
      indexedInstances = builtins.genList (i: {
        index = i;
        instance = builtins.elemAt instances i;
      }) (builtins.length instances);
    in
    {
      containers = builtins.listToAttrs (
        map (x: {
          name = containerName x.instance;
          value = containerFor x.index x.instance;
        }) indexedInstances
      );

      networks.${name} = {
        networkConfig = {
          subnets = [ "10.90.92.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
        serviceConfig.Slice = appServiceConfig.Slice;
      };
    };
}
