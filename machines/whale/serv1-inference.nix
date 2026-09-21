{
  config,
  lib,
  pkgs,
  ...
}:
let
  knownHosts = pkgs.writeText "serv1-known-hosts" ''
    serv1.asc.rssi.ru ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE8TTjcHEdbMhYVqPZMX5Jhujo1X/WzlUJmMSthjne3f
  '';
in
{
  age.secrets.serv1-inference-ssh.file = ./serv1-inference-ssh.age;

  systemd.services.serv1-inference = {
    description = "SSH tunnel to serv1 inference API through mole";
    wantedBy = [ "multi-user.target" ];
    wants = [
      "network-online.target"
      "nebula@averyan.service"
    ];
    after = [
      "network-online.target"
      "nebula@averyan.service"
      "litellm-network.service"
    ];
    # Retry indefinitely when mole or serv1 is unavailable.
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      DynamicUser = true;
      LoadCredential = "ssh-key:${config.age.secrets.serv1-inference-ssh.path}";
      ExecStart = lib.concatStringsSep " " [
        "${pkgs.openssh}/bin/ssh -F /dev/null -NT"
        "-i %d/ssh-key -o IdentitiesOnly=yes -o BatchMode=yes"
        "-o StrictHostKeyChecking=yes -o UserKnownHostsFile=${knownHosts}"
        "-o GlobalKnownHostsFile=/dev/null -o HostKeyAlias=serv1.asc.rssi.ru"
        "-o ExitOnForwardFailure=yes -o ConnectTimeout=15"
        "-o ServerAliveInterval=30 -o ServerAliveCountMax=3"
        "-L 127.0.0.1:28001:127.0.0.1:19088"
        "-L 10.90.95.1:28001:127.0.0.1:19088"
        "-p 3122 averyan@10.57.1.42"
      ];
      Restart = "always";
      RestartSec = "15s";
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ProtectKernelTunables = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictSUIDSGID = true;
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      CapabilityBoundingSet = "";
      UMask = "0077";
    };
  };

  # Only LiteLLM's bridge may reach the host listener; no public port is opened.
  networking.firewall.interfaces.pme-litellm.allowedTCPPorts = [ 28001 ];
}
