let
  name = "avitobot";
  subnet = "10.90.103";
  image = "ghcr.io/averyanalex/wondercraft-ai-manager:latest";
  serviceConfig = {
    Slice = "apps-${name}.slice";
    RestartMode = "direct";
    RestartSec = "10s";
    TimeoutStartSec = "5min";
    TimeoutStopSec = "45s";
  };
  unitConfig = {
    StartLimitIntervalSec = "10min";
    StartLimitBurst = 6;
  };
  uidMaps = [ "0:100000:100000" ];
  gidMaps = [ "0:100000:100000" ];
in
{ config, ... }:
let
  network = config.virtualisation.quadlet.networks.${name}.ref;
  auth = [ "REGISTRY_AUTH_FILE=${config.environment.sessionVariables.REGISTRY_AUTH_FILE}" ];
  environment = {
    WONDERCRAFT_ENVIRONMENT = "production";
    WONDERCRAFT_AUTOMATION_HARD_KILL = "true";
    WONDERCRAFT_AVITO_SENDS_ENABLED = "false";
    WONDERCRAFT_AVITO_ENABLED = "true";
    WONDERCRAFT_AVITO_WEBHOOK_ENABLED = "true";
    # Enable order processing after the registry is imported.
    WONDERCRAFT_AVITO_ORDER_POLL_ENABLED = "false";
    WONDERCRAFT_TELEGRAM_ENABLED = "true";
    WONDERCRAFT_TELEGRAM_POLLING_ENABLED = "true";
    WONDERCRAFT_OPENROUTER_ENABLED = "true";
    WONDERCRAFT_S3_ENABLED = "true";
    WONDERCRAFT_S3_ENDPOINT_URL = "https://storage.yandexcloud.net";
    WONDERCRAFT_S3_REGION = "ru-central1";
    WONDERCRAFT_S3_BUCKET = "wondercraft-media";
    WONDERCRAFT_MEDIA_ROOT_PREFIX = "";
  };
in
{
  age.secrets."${name}-env".file = ./env.age;
  age.secrets."${name}-db".file = ./db.age;
  # Use whale's existing outbound routing, as the memexpert containers do.
  networking.tproxy.forward."pme-${name}" = { };
  systemd.slices."apps-${name}".description = "WonderCraft Avito manager";
  systemd.tmpfiles.rules = [ "d /persist/${name}/db 700 100999 100999 - -" ];
  services.nginx.virtualHosts."wondercraftaimanager.averyan.ru" = {
    useACMEHost = "averyan.ru";
    forceSSL = true;
    # The opaque webhook path is a credential; do not log request URLs.
    extraConfig = ''
      access_log off;
      error_log /dev/null;
      client_max_body_size 1m;
    '';
    locations."/".proxyPass = "http://${subnet}.2:8000";
    locations."= /health/ready".extraConfig = "return 404;";
  };
  virtualisation.quadlet.networks.${name} = {
    networkConfig = {
      subnets = [ "${subnet}.0/24" ];
      podmanArgs = [ "--interface-name=pme-${name}" ];
    };
    serviceConfig.Slice = serviceConfig.Slice;
  };
  virtualisation.quadlet.containers = {
    "${name}-db" = {
      containerConfig = {
        # Database upgrades are explicit, never unattended Reploy updates.
        image = "docker.io/library/postgres:18.4@sha256:3a82e1f56c8f0f5616a11103ac3d47e632c3938698946a7ad26da0df1334744a";
        memory = "1g";
        networks = [ network ];
        ip = "${subnet}.3";
        environments = {
          POSTGRES_USER = "wondercraft";
          POSTGRES_DB = "wondercraft";
        };
        environmentFiles = [ config.age.secrets."${name}-db".path ];
        volumes = [ "/persist/${name}/db:/var/lib/postgresql" ];
        healthCmd = "pg_isready -U wondercraft -d wondercraft";
        healthInterval = "10s";
        healthTimeout = "5s";
        healthRetries = 12;
        healthStartPeriod = "15s";
        notify = "healthy";
        inherit uidMaps gidMaps;
      };
      inherit unitConfig serviceConfig;
    };
    "${name}-migrate" = {
      containerConfig = {
        inherit image uidMaps gidMaps;
        autoUpdate = "registry";
        memory = "512m";
        networks = [ network ];
        environmentFiles = [ config.age.secrets."${name}-env".path ];
        exec = [
          "alembic"
          "upgrade"
          "head"
        ];
      };
      unitConfig = unitConfig // {
        Requires = [ "${name}-db.service" ];
        After = [ "${name}-db.service" ];
      };
      serviceConfig = serviceConfig // {
        Type = "oneshot";
        # As in memexpert, every app restart reruns migrations for the new image.
        RemainAfterExit = false;
        Restart = "on-failure";
        Environment = auth;
      };
    };
    "${name}-app" = {
      containerConfig = {
        inherit image uidMaps gidMaps;
        autoUpdate = "registry";
        memory = "1g";
        networks = [ network ];
        ip = "${subnet}.2";
        environments = environment;
        environmentFiles = [ config.age.secrets."${name}-env".path ];
        stopTimeout = 30;
        healthCmd = "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health/live', timeout=3)\"";
        healthInterval = "15s";
        healthTimeout = "5s";
        healthRetries = 12;
        healthStartPeriod = "30s";
        healthOnFailure = "kill";
        notify = "healthy";
      };
      unitConfig = unitConfig // {
        Requires = [ "${name}-migrate.service" ];
        After = [ "${name}-migrate.service" ];
      };
      serviceConfig = serviceConfig // {
        Environment = auth;
      };
    };
  };
}
