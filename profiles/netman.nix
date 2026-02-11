{lib, ...}: {
  networking.networkmanager.enable = true;
  # networking.networkmanager.wifi.backend = "iwd";

  systemd.services.NetworkManager-wait-online.enable = false;

  networking.networkmanager.dns = lib.mkForce "none";

  # systemd.services.systemd-resolved.unitConfig.After = ["NetworkManager.service"];

  persist.state.dirs = [
    "/etc/NetworkManager"
    "/var/lib/NetworkManager"
    # "/var/lib/iwd"
  ];
}
