{ modulesPath, ... }:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ./sdboot.nix
  ];

  # QEMU
  services.qemuGuest.enable = true;

  # Storage
  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "sr_mod"
    "virtio_blk"
  ];

  # Intel
  boot.kernelModules = [ "kvm-intel" ];
  hardware.enableRedistributableFirmware = false;
}
