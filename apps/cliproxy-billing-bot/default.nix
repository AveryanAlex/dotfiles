let
  name = "cliproxy-billing-bot";
  sliceName = "apps-${name}";
  appServiceConfig = {
    Slice = "${sliceName}.slice";
    RestartMode = "direct";
    RestartSec = "10s";
    TimeoutStartSec = "4min";
    TimeoutStopSec = "45s";
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
    container = name;
    databases = [
      {
        host = "/persist/${name}/data/billing.db";
        path = "/data/billing.db";
        target = "billing.db";
      }
    ];
  };
in
{
  services.rusticBackup.jobs.${name} = {
    paths = [ "/persist/${name}/data" ];
    exclude = sqliteBackup.exclude ++ [ "/persist/${name}/data/.rustic-backup.*" ];
    requiresUnits = [ "${name}.service" ];
    runtimePackages = [ config.virtualisation.podman.package ];
    backupStaging = true;
    inherit (sqliteBackup) prepareScript;
  };

  systemd.slices.${sliceName}.description = "CLIProxyAPI billing bot";

  systemd.tmpfiles.rules = [
    "d /persist/${name} 700 100000 100000 - -"
    # The image runs as UID/GID 10001 inside the standard rootless Podman map.
    "d /persist/${name}/data 700 110001 110001 - -"
  ];

  age.secrets.${name}.file = ./env.age;

  virtualisation.quadlet.containers.${name} = {
    containerConfig = {
      image = "ghcr.io/averyanalex/cliproxy-billing-bot:main";
      autoUpdate = "registry";
      memory = "512m";
      networks = [ config.virtualisation.quadlet.networks.cliproxyapi.ref ];
      volumes = [
        "/persist/${name}/data:/data"
        sqliteBackup.volume
      ];
      environments = {
        KEEPER_BASE_URL = "http://cliproxyapi-usage-keeper:8080/usage/api/v1";
        DATABASE_URL = "sqlite+aiosqlite:////data/billing.db";
        TIME_ZONE = "Europe/Moscow";
      };
      environmentFiles = [ config.age.secrets.${name}.path ];
      stopTimeout = 30;
      gidMaps = [ "0:100000:100000" ];
      uidMaps = [ "0:100000:100000" ];
    };
    unitConfig = appUnitConfig // rec {
      Requires = [ "cliproxyapi-usage-keeper.service" ];
      After = Requires;
    };
    serviceConfig = appServiceConfig // {
      Environment = [
        "REGISTRY_AUTH_FILE=${config.environment.sessionVariables.REGISTRY_AUTH_FILE}"
      ];
    };
  };
}
