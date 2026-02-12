{
  config,
  inputs,
  pkgs,
  secrets,
  ...
}:
let
  cpmbot-pkg = inputs.cpmbot.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  age.secrets.cpmbot.file = "${secrets}/creds/cpmbot.age";

  systemd.services.cpmbot = {
    after = [
      "network-online.target"
      "postgresql.service"
    ];
    wants = [ "network-online.target" ];
    requires = [ "postgresql.service" ];
    path = [ cpmbot-pkg ];
    environment = {
      DATABASE_URL = "postgresql:///cpmbot";
    };
    serviceConfig = {
      User = "cpmbot";
      Group = "cpmbot";
      EnvironmentFile = config.age.secrets.cpmbot.path;
      ExecStart = "${cpmbot-pkg}/bin/cpmbot";
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

  services.postgresql = {
    ensureDatabases = [ "cpmbot" ];
    ensureUsers = [
      {
        name = "cpmbot";
        ensureDBOwnership = true;
      }
    ];
  };

  users = {
    users.cpmbot = {
      isSystemUser = true;
      description = "CPM Bot";
      group = "cpmbot";
    };
    groups.cpmbot = { };
  };
}
