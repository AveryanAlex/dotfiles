{
  config,
  inputs,
  pkgs,
  secrets,
  ...
}:
let
  aplusmuz-music-scraper-pkg =
    inputs.aplusmuz-music-scraper.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  age.secrets.aplusmuz-music-scraper.file = "${secrets}/creds/aplusmuz-music-scraper.age";

  systemd.services.aplusmuz-music-scraper = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ aplusmuz-music-scraper-pkg ];

    serviceConfig = {
      User = "aplusmuz-music-scraper";
      Group = "aplusmuz-music-scraper";
      WorkingDirectory = "/var/lib/aplusmuz-music-scraper";
      StateDirectory = "aplusmuz-music-scraper";
      EnvironmentFile = config.age.secrets.aplusmuz-music-scraper.path;
      ExecStart = "${aplusmuz-music-scraper-pkg}/bin/bot";
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

  users = {
    users.aplusmuz-music-scraper = {
      isSystemUser = true;
      uid = 659;
      group = "aplusmuz-music-scraper";
    };
    groups.aplusmuz-music-scraper.gid = 659;
  };

  persist.state.dirs = [
    {
      directory = "/var/lib/aplusmuz-music-scraper";
      user = "aplusmuz-music-scraper";
      group = "aplusmuz-music-scraper";
    }
  ];
}
