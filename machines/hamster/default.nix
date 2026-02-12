{
  inputs,
  ...
}:
{
  imports = [
    ../../roles/desktop

    ../../profiles/bluetooth.nix
    ../../profiles/netman.nix
    ../../profiles/libvirt.nix
    # inputs.self.nixosModules.profiles.secureboot
    # inputs.self.nixosModules.profiles.pmbootstrap
    # inputs.self.nixosModules.profiles.remote-builder-client

    inputs.self.nixosModules.hardware.thinkbook

    ./mounts.nix
  ];

  # networking.firewall.extraForwardRules = ''
  #   iifname wlp0s20f3 accept
  # '';
  # networking.nat.internalInterfaces = ["wlp0s20f3"];

  persist.tmpfsSize = "6G";

  # services.power-profiles-daemon.enable = false;
  services.tlp = {
    # enable = true;
    settings = {
      STOP_CHARGE_THRESH_BAT0 = 1;
    };
  };

  # services.logind.extraConfig = ''
  #   HandlePowerKey=hibernate
  #   HandleLidSwitch=suspend-then-hibernate
  #   HandleLidSwitchExternalPower=ignore
  # ''; # TODO: port

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendEstimationSec=15m
  '';

  system.stateVersion = "24.11";
}
