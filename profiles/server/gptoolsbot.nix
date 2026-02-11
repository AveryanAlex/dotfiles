{
  config,
  inputs,
  pkgs,
  ...
}:
let
  gptoolsbot-pkg = inputs.gptoolsbot.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  age.secrets.gptoolsbot.file = ../../secrets/creds/gptoolsbot.age;
  systemd.services.gptoolsbot = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    path = [ gptoolsbot-pkg ];
    environment = {
      https_proxy = "http://127.0.0.1:8080";
    };
    serviceConfig = {
      EnvironmentFile = config.age.secrets.gptoolsbot.path;
      User = "gptoolsbot";
      Group = "gptoolsbot";

      Restart = "on-failure";
      RestartSec = "5s";

      ExecStart = "${gptoolsbot-pkg}/bin/bot";
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
}
