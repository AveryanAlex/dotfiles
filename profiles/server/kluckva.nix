{
  config,
  inputs,
  pkgs,
  ...
}:
let
  infinitytgadminsbot-pkg =
    inputs.infinitytgadminsbot.packages.${pkgs.stdenv.hostPlatform.system}.default;

  makeService = name: {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ infinitytgadminsbot-pkg ];
    environment.RUST_LOG = "info";
    serviceConfig = {
      EnvironmentFile = config.age.secrets."infinitytgadminsbot-${name}".path;
      User = "infinitytgadminsbot-${name}";
      Group = "infinitytgadminsbot-${name}";

      Restart = "on-failure";
      RestartSec = "5s";

      ExecStart = "${infinitytgadminsbot-pkg}/bin/infinitytgadminsbot";
      DynamicUser = true;

      # Hardening
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      DevicePolicy = "closed";
      NoNewPrivileges = true; # Implied by DynamicUser
      PrivateUsers = true;
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
      RestrictRealtime = true;
      RestrictSUIDSGID = true; # Implied by DynamicUser
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
      ];
      UMask = "0077";
    };
    wantedBy = [ "multi-user.target" ];
  };
in
{
  age.secrets.infinitytgadminsbot-kluckva.file = ../../secrets/creds/kluckva.age;
  systemd.services.infinitytgadminsbot-kluckva = makeService "kluckva";

  age.secrets.infinitytgadminsbot-eye210.file = ../../secrets/creds/infinitytgadminsbot-eye210.age;
  systemd.services.infinitytgadminsbot-eye210 = makeService "eye210";
}
