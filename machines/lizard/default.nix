{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../roles/core
    ../../profiles/zram.nix

    # inputs.self.nixosModules.profiles.server.hass
    # inputs.self.nixosModules.profiles.server.pgsql

    inputs.self.nixosModules.hardware.rpi4

    ./mounts.nix
    ./network.nix

    ./mqtt.nix

    ./hass.nix
    ./frigate.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # hardware.bluetooth.enable = true;

  persist.enable = lib.mkForce false;

  system.stateVersion = "25.05";
}
