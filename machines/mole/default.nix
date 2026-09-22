{ lib, ... }:
{
  imports = [
    ../../roles/server.nix

    ../../profiles/netman.nix

    ./hardware.nix
    ./mounts.nix
    ./ssh-proxies.nix
  ];

  persist.enable = lib.mkForce false;
  services.syncthing.enable = lib.mkForce false;
  services.displayManager.autoLogin.enable = false;

  system.stateVersion = "26.05";
}
