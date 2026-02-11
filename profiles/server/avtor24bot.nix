{
  inputs,
  pkgs,
  ...
}: let
  package = inputs.avtor24bot.packages.${pkgs.stdenv.hostPlatform.system}.default;
in {
  users.users.avtor24bot = {
    uid = 721;
    isSystemUser = true;
    home = "/var/lib/avtor24bot";
    group = "avtor24bot";
  };
  users.groups.avtor24bot.gid = 721;

  systemd.services.avtor24bot = {
    after = ["network-online.target"];
    wants = ["network-online.target"];
    path = [package];
    serviceConfig = {
      User = "avtor24bot";
      Group = "avtor24bot";

      WorkingDirectory = "/var/lib/avtor24bot";
      StateDirectory = "avtor24bot";

      Restart = "on-failure";
      RestartSec = "5s";

      ExecStart = "${package}/bin/app";

      CapabilityBoundingSet = "";
      NoNewPrivileges = true;
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
      RestrictAddressFamilies = ["AF_INET" "AF_INET6"];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      PrivateMounts = true;
    };
    wantedBy = ["multi-user.target"];
  };

  persist.state.dirs = [
    {
      directory = "/var/lib/avtor24bot";
      user = "avtor24bot";
      group = "avtor24bot";
      mode = "0700";
    }
  ];
}
