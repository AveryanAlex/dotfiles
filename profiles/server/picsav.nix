{
  config,
  inputs,
  pkgs,
  ...
}:
let
  picsavbot-pkg = inputs.picsavbot.packages.${pkgs.stdenv.hostPlatform.system}.default;

  dockerImage = pkgs.dockerTools.pullImage {
    imageName = "averyanalex/picsavai";
    finalImageTag = "latest";
    imageDigest = "sha256:8a9c7622365976ba37fe23d166c80a1e5a68226e221e31890ae5516c215d3c08";
    sha256 = "4ArRTQkSXLPDdYpU7DyEsHF/0EzMlgWyHw5CQn06jp8=";
  };
in
{
  age.secrets.picsav.file = ../../secrets/creds/picsavbot.age;

  virtualisation.oci-containers = {
    containers = {
      picsavai = {
        image = "averyanalex/picsavai";
        imageFile = dockerImage;
        extraOptions = [ "--network=host" ];
      };
    };
  };

  systemd.services.picsavbot = {
    after = [
      "network-online.target"
      "postgresql.service"
      "podman-picsavai.service"
    ];
    wants = [ "network-online.target" ];
    requires = [
      "postgresql.service"
      "podman-picsavai.service"
    ];
    path = [ picsavbot-pkg ];
    environment = {
      DATABASE_URL = "postgresql:///picsav";
    };
    serviceConfig = {
      User = "picsav";
      Group = "picsav";
      EnvironmentFile = config.age.secrets.picsav.path;
      ExecStart = "${picsavbot-pkg}/bin/picsavbot";

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
    ensureDatabases = [ "picsav" ];
    ensureUsers = [
      {
        name = "picsav";
        ensureDBOwnership = true;
      }
    ];
  };

  users = {
    users.picsav = {
      isSystemUser = true;
      description = "PicSav";
      group = "picsav";
    };
    groups.picsav = { };
  };
}
