{
  config,
  inputs,
  pkgs,
  secrets,
  ...
}:
let
  anoquebot-pkg = inputs.anoquebot.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  age.secrets.anoquebot.file = "${secrets}/creds/anoquebot.age";

  systemd.services.anoquebot = {
    after = [
      "network-online.target"
      "postgresql.service"
    ];
    wants = [ "network-online.target" ];
    requires = [ "postgresql.service" ];
    path = [ anoquebot-pkg ];

    environment = {
      DATABASE_URL = "postgresql:///anoquebot";
    };

    serviceConfig = {
      User = "anoquebot";
      Group = "anoquebot";
      EnvironmentFile = config.age.secrets.anoquebot.path;
      ExecStart = "${anoquebot-pkg}/bin/anoquebot";

      Restart = "on-failure";
      RestartSec = "5s";

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

  services.postgresql = {
    ensureDatabases = [ "anoquebot" ];
    ensureUsers = [
      {
        name = "anoquebot";
        ensureDBOwnership = true;
      }
    ];
  };

  users = {
    users.anoquebot = {
      isSystemUser = true;
      # description = "GayRadar";
      group = "anoquebot";
    };
    groups.anoquebot = { };
  };
}
