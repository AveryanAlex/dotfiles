{
  imports = [
    ../../profiles/bluetooth.nix
    ../../profiles/corectrl.nix
    ../../profiles/netman.nix
    ../../profiles/openrgb.nix
    ../../profiles/libvirt.nix
    ../../profiles/persist-yggdrasil.nix
    ../../profiles/pmbootstrap.nix
    ../../roles/desktop

    ./hardware.nix
    ./mounts.nix
  ];

  system.stateVersion = "24.05";

  networking.nat.externalInterface = "wlan0";

  networking.nat.forwardPorts = [
    {
      sourcePort = 8080;
      proto = "tcp";
      destination = "10.90.85.10:8080";
    }
  ];
}
