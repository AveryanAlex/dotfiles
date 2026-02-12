{
  config,
  inputs,
  pkgs,
  secrets,
  ...
}:
let
  bvilovebot-pkg = inputs.bvilovebot.packages.${pkgs.stdenv.hostPlatform.system}.default;
  bvilovebot-beta-pkg = inputs.bvilovebot-beta.packages.${pkgs.stdenv.hostPlatform.system}.default;

  commonService = {
    after = [
      "network-online.target"
      "postgresql.service"
    ];
    wants = [ "network-online.target" ];
    requires = [ "postgresql.service" ];
    serviceConfig = {
      Restart = "always";

      # Capabilities
      CapabilityBoundingSet = "";
      # Security
      NoNewPrivileges = true;
      # Sandboxing
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProtectHostname = true;
      ProtectClock = true;
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectKernelLogs = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_UNIX AF_INET AF_INET6" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      PrivateMounts = true;
    };
    wantedBy = [ "multi-user.target" ];
  };
in
{
  age.secrets.bvilove.file = "${secrets}/creds/bvilove.age";
  age.secrets.bvilove-beta.file = "${secrets}/creds/bvilove-beta.age";

  systemd.services.bvilovebot = commonService // {
    path = [ bvilovebot-pkg ];
    environment = {
      DATABASE_URL = "postgresql:///bvilove";
    };
    serviceConfig = {
      User = "bvilove";
      Group = "bvilove";
      EnvironmentFile = config.age.secrets.bvilove.path;
      ExecStart = "${bvilovebot-pkg}/bin/bvilovebot";
    };
  };

  systemd.services.bvilovebot-beta = commonService // {
    path = [ bvilovebot-beta-pkg ];
    environment = {
      DATABASE_URL = "postgresql:///bvilovebeta";
    };
    serviceConfig = {
      User = "bvilovebeta";
      Group = "bvilovebeta";
      EnvironmentFile = config.age.secrets.bvilove-beta.path;
      ExecStart = "${bvilovebot-beta-pkg}/bin/bvilovebot";
    };
  };

  services.postgresql = {
    ensureDatabases = [
      "bvilove"
      "bvilovebeta"
    ];
    ensureUsers = [
      {
        name = "bvilove";
        ensureDBOwnership = true;
      }
      {
        name = "bvilovebeta";
        ensureDBOwnership = true;
      }
    ];
  };

  users = {
    users.bvilove = {
      isSystemUser = true;
      description = "BVI Love";
      group = "bvilove";
    };
    groups.bvilove = { };
    users.bvilovebeta = {
      isSystemUser = true;
      description = "BVI Love Beta";
      group = "bvilovebeta";
    };
    groups.bvilovebeta = { };
  };
}
