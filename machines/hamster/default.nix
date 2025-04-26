{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.self.nixosModules.roles.desktop

    inputs.self.nixosModules.profiles.bluetooth
    inputs.self.nixosModules.profiles.netman
    inputs.self.nixosModules.profiles.libvirt
    # inputs.self.nixosModules.profiles.secureboot
    # inputs.self.nixosModules.profiles.pmbootstrap
    # inputs.self.nixosModules.profiles.remote-builder-client

    inputs.self.nixosModules.hardware.thinkbook

    ./mounts.nix
  ];

  persist.tmpfsSize = "6G";

  services.tlp = {
    # enable = true;
    settings = {
      STOP_CHARGE_THRESH_BAT0 = 0;
    };
  };

  services.logind.extraConfig = ''
    HandlePowerKey=hibernate
    HandleLidSwitch=suspend-then-hibernate
    HandleLidSwitchExternalPower=ignore
  '';

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendEstimationSec=15m
  '';

  system.stateVersion = "24.11";
}
