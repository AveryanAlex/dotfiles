{
  users.users.nix-remote-builder = {
    openssh.authorizedKeys.keys = [
      ''command="nix-daemon --stdio",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDtlNhVmVCNT7uCUUHS/BfdLWKVCb1M8JyD8DkmHASR7''
    ];
    isNormalUser = true;
    group = "nogroup";
  };
  nix.settings.trusted-users = [ "nix-remote-builder" ];
}
