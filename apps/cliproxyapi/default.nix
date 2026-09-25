let
  name = "cliproxyapi";
  keeperName = "${name}-usage-keeper";
  keeperBasePath = "/usage";
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
    container = "cliproxyapi-usage-keeper";
    databases = [
      {
        host = "/persist/cliproxyapi/usage-keeper/app.db";
        path = "/data/app.db";
        target = "app.db";
      }
    ];
  };
in
{
  services.rusticBackup.jobs.cliproxyapi = {
    paths = [
      "/persist/cliproxyapi/config.yaml"
      "/persist/cliproxyapi/auths"
      "/persist/cliproxyapi/usage-keeper"
    ];
    exclude = sqliteBackup.exclude ++ [
      "/persist/cliproxyapi/usage-keeper/logs"
      "/persist/cliproxyapi/usage-keeper/backups"
    ];
    requiresUnits = [ "cliproxyapi-usage-keeper.service" ];
    runtimePackages = [ config.virtualisation.podman.package ];
    backupStaging = true;
    inherit (sqliteBackup) prepareScript;
  };

  systemd.slices.${sliceName}.description = "CLIProxyAPI application services";

  systemd.tmpfiles.rules = [
    "d /persist/${name} 700 100000 100000 - -"
    "d /persist/${name}/auths 700 100000 100000 - -"
    "d /persist/${name}/logs 700 100000 100000 - -"
    "d /persist/${name}/usage-keeper 700 100000 100000 - -"
  ];

  age.secrets.${name}.file = ./main.age;

  services.nginx.virtualHosts."cli.neutrino.su" = {
    useACMEHost = "neutrino.su";
    forceSSL = true;

    locations."= ${keeperBasePath}".extraConfig = ''
      return 302 ${keeperBasePath}/;
    '';

    locations."${keeperBasePath}/" = {
      proxyPass = "http://10.90.96.3:8080";
      proxyWebsockets = true;

      extraConfig = ''
        proxy_connect_timeout 1h;
        proxy_send_timeout 1h;
        proxy_read_timeout 1h;
        send_timeout 1h;
      '';
    };

    locations."/" = {
      proxyPass = "http://10.90.96.2:8317";
      proxyWebsockets = true;

      extraConfig = ''
        proxy_connect_timeout 1h;
        proxy_send_timeout 1h;
        proxy_read_timeout 1h;
        send_timeout 1h;
      '';
    };
  };

  networking.tproxy.forward."pme-${name}" = { };

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers.${name} = {
        containerConfig = {
          image = "docker.io/eceasy/cli-proxy-api:latest";
          autoUpdate = "registry";
          memory = "4g";
          networks = [ networks.${name}.ref ];
          ip = "10.90.96.2";
          volumes = [
            "/persist/${name}/config.yaml:/CLIProxyAPI/config.yaml"
            "/persist/${name}/auths:/root/.cli-proxy-api"
            "/persist/${name}/logs:/CLIProxyAPI/logs"
          ];
          environments = {
            TZ = "Europe/Moscow";
          };
          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];
        };
        unitConfig = appUnitConfig;
        serviceConfig = appServiceConfig // {
          EnvironmentFile = config.age.secrets.${name}.path;
        };
      };

      containers.${keeperName} = {
        containerConfig = {
          image = "ghcr.io/willxup/cpa-usage-keeper:latest";
          autoUpdate = "registry";
          memory = "1g";
          networks = [ networks.${name}.ref ];
          ip = "10.90.96.3";
          volumes = [
            "/persist/${name}/usage-keeper:/data"
            sqliteBackup.volume
          ];
          environments = {
            APP_BASE_PATH = keeperBasePath;
            APP_PORT = "8080";
            AUTH_ENABLED = "true";
            CPA_BASE_URL = "http://${name}:8317";
            REDIS_QUEUE_ADDR = "${name}:8317";
            TZ = "Europe/Moscow";
            WORK_DIR = "/data";
          };
          environmentFiles = [ config.age.secrets.${name}.path ];
          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];
        };
        unitConfig = appUnitConfig // rec {
          Requires = [ "${name}.service" ];
          After = Requires;
        };
        serviceConfig = appServiceConfig;
      };

      networks.${name} = {
        networkConfig = {
          subnets = [ "10.90.96.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
        serviceConfig.Slice = appServiceConfig.Slice;
      };
    };
}
