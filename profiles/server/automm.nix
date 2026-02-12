{
  config,
  inputs,
  pkgs,
  secrets,
  ...
}:
let
  automm-pkg = inputs.automm.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (
    final: prev: {
      RUSTFLAGS = "-Ctarget-cpu=neoverse-n1";
    }
  );
in
{
  age.secrets.automm.file = "${secrets}/creds/automm.age";
  systemd.services.automm = {
    after = [
      "network-online.target"
      "influxdb2.service"
    ];
    wants = [ "network-online.target" ];
    requires = [ "influxdb2.service" ];
    path = [ automm-pkg ];
    # environment.RUST_LOG = "warn";
    serviceConfig = {
      EnvironmentFile = config.age.secrets.automm.path;
      User = "automm";
      Group = "automm";

      ExecStart = "${automm-pkg}/bin/automm";
      DynamicUser = true;

      # CPUSchedulingPolicy = "rr";
      # CPUSchedulingPriority = 20;
      # IOSchedulingPriority = 1;
      # Nice = -10;
      AmbientCapabilities = "CAP_SYS_NICE";
      CapabilityBoundingSet = "CAP_SYS_NICE";
      RestrictRealtime = false;

      Restart = "on-failure";
      RestartSec = "5s";

      # Hardening
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      DevicePolicy = "closed";
      NoNewPrivileges = true; # Implied by DynamicUser
      # PrivateUsers = true;
      PrivateTmp = true; # Implied by DynamicUser
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProcSubset = "pid";
      ProtectSystem = "strict";
      RemoveIPC = true; # Implied by DynamicUser
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
      ];
      RestrictNamespaces = true;
      RestrictSUIDSGID = true; # Implied by DynamicUser
      SystemCallArchitectures = "native";
      # SystemCallFilter = [
      #   "@system-service"
      # ];
      UMask = "0077";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
