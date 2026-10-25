# SSH defaults and known hosts adapted from srvos. See ../LICENSES/srvos-MIT.txt.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      GatewayPorts = "clientspecified";
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      UseDns = false;
      StreamLocalBindUnlink = true;
      KexAlgorithms = [
        "curve25519-sha256"
        "curve25519-sha256@libssh.org"
        "diffie-hellman-group16-sha512"
        "diffie-hellman-group18-sha512"
        "sntrup761x25519-sha512@openssh.com"
      ];
    };

    # Git hosting services manage their own authorized_keys files.
    authorizedKeysFiles = lib.mkIf (
      !config.services.gitea.enable
      && !config.services.gitlab.enable
      && !config.services.gitolite.enable
      && !config.services.gerrit.enable
      && !config.services.forgejo.enable
    ) (lib.mkForce [ "/etc/ssh/authorized_keys.d/%u" ]);
  };

  programs.ssh.knownHosts = {
    "github.com" = {
      hostNames = [ "github.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    };
    "gitlab.com" = {
      hostNames = [ "gitlab.com" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
    };
    "git.sr.ht" = {
      hostNames = [ "git.sr.ht" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMZvRd4EtM7R+IHVMWmDkVU3VLQTSwQDSAvW0t2Tkj60";
    };
  };

  systemd.services.openssh.after = [ "nebula@averyan.service" ];

  environment.systemPackages = [ pkgs.mosh ];
  networking.firewall = {
    allowedTCPPorts = [ 22 ];
    allowedUDPPortRanges = [
      {
        from = 60000;
        to = 61000;
      }
    ];
  };
}
