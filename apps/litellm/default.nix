let
  name = "litellm";
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
  vhost = acmeHost: {
    useACMEHost = acmeHost;
    forceSSL = true;

    locations."/" = {
      proxyPass = "http://10.90.95.2:4000";
      proxyWebsockets = true;

      extraConfig = ''
        proxy_connect_timeout 900s;
        proxy_send_timeout 900s;
        proxy_read_timeout 900s;
        send_timeout 900s;
        proxy_buffering off;
      '';
    };
  };
in
{ config, ... }:
{
  services.rusticBackup.jobs.litellm = {
    requiresUnits = [ "litellm-db.service" ];
    runtimePackages = [ config.virtualisation.podman.package ];
    backupStaging = true;
    prepareScript = ''
      podman exec --user postgres litellm-db pg_dump \
        --username=litellm --no-password --format=custom --compress=0 litellm \
        > "$BACKUP_STAGING_DIR/litellm.dump"
    '';
  };

  systemd.slices.${sliceName}.description = "LiteLLM application services";

  systemd.tmpfiles.rules = [
    "d /persist/${name}/db 700 100999 100999 - -"
  ];

  services.nginx.virtualHosts = {
    "litellm.averyan.ru" = vhost "averyan.ru";
    "litellm.neutrino.su" = vhost "neutrino.su";
  };

  # TODO: restrict nebula egress to specific hosts/ports instead of full network access
  networking.firewall.extraForwardRules = ''iifname pme-${name} oifname "nebula.averyan" accept'';
  networking.nftables.tables."${name}-nat" = {
    family = "inet";
    content = ''
      chain post {
        type nat hook postrouting priority srcnat; policy accept;
        iifname pme-${name} oifname "nebula.averyan" masquerade
      }
    '';
  };

  age.secrets.${name}.file = ./main.age;

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.${name} = {
        networkConfig = {
          subnets = [ "10.90.95.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
        serviceConfig.Slice = appServiceConfig.Slice;
      };

      containers."${name}-db" = {
        containerConfig = {
          image = "docker.io/library/postgres:17";
          autoUpdate = "registry";
          memory = "2g";
          networks = [ networks.${name}.ref ];
          ip = "10.90.95.3";
          environments = {
            POSTGRES_DB = name;
            POSTGRES_USER = name;
            POSTGRES_PASSWORD = name;
          };
          volumes = [ "/persist/${name}/db:/var/lib/postgresql/data" ];
          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];
        };
        unitConfig = appUnitConfig;
        serviceConfig = appServiceConfig;
      };

      containers."${name}-app" = {
        containerConfig = {
          image = "ghcr.io/berriai/litellm-database:main-latest";
          autoUpdate = "registry";
          memory = "4g";
          networks = [ networks.${name}.ref ];
          ip = "10.90.95.2";
          environments = {
            DATABASE_URL = "postgresql://${name}:${name}@${name}-db:5432/${name}";
            STORE_MODEL_IN_DB = "True";
          };
          environmentFiles = [ config.age.secrets.${name}.path ];
          volumes = [
            "${./config.yml}:/app/config.yaml:ro"
          ];
          exec = "--config=/app/config.yaml";
          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];
        };
        unitConfig = appUnitConfig // rec {
          Requires = [
            "${name}-db.service"
          ];
          After = Requires;
        };
        serviceConfig = appServiceConfig;
      };
    };
}
