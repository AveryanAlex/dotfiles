{
  config,
  inputs,
  pkgs,
  secrets,
  ...
}:
let
  gayradarbot-pkg = inputs.gayradarbot.packages.${pkgs.stdenv.hostPlatform.system}.default;

  dockerImage = pkgs.dockerTools.pullImage {
    imageName = "averyanalex/gayradarai";
    finalImageTag = "latest";
    imageDigest = "sha256:8e63a69bbf758accc8e8d2005444c6fddb673c36aaba6e60b81625223677c8e0";
    sha256 = "QQ2gAioJy8Aj369x7P04QQw/uPSekrstHClTDolF1Tk=";
  };
in
{
  age.secrets.gayradar.file = "${secrets}/creds/gayradar.age";

  virtualisation.oci-containers = {
    containers = {
      gayradarai = {
        image = "averyanalex/gayradarai";
        imageFile = dockerImage;
        extraOptions = [ "--network=host" ];
      };
    };
  };

  systemd.services.gayradarbot = {
    after = [
      "network-online.target"
      "postgresql.service"
      "podman-gayradarai.service"
    ];
    wants = [ "network-online.target" ];
    requires = [
      "postgresql.service"
      "podman-gayradarai.service"
    ];
    path = [ gayradarbot-pkg ];
    environment = {
      DATABASE_URL = "postgresql:///gayradar";
    };
    serviceConfig = {
      User = "gayradar";
      Group = "gayradar";
      EnvironmentFile = config.age.secrets.gayradar.path;
      ExecStart = "${gayradarbot-pkg}/bin/gayradarbot";

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
    ensureDatabases = [ "gayradar" ];
    ensureUsers = [
      {
        name = "gayradar";
        ensureDBOwnership = true;
      }
    ];
  };

  users = {
    users.gayradar = {
      isSystemUser = true;
      description = "GayRadar";
      group = "gayradar";
    };
    groups.gayradar = { };
  };
}
