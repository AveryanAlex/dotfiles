{ inputs, ... }:
{
  imports = [
    # inputs.self.nixosModules.roles.desktop
    ../../roles/family.nix

    ../../profiles/bluetooth.nix
    ../../profiles/netman.nix
    # inputs.self.nixosModules.profiles.remote-builder-client

    inputs.self.nixosModules.hardware.thinkbook

    ./mounts.nix
  ];

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

  system.stateVersion = "23.05";
}
