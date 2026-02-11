{ modulesPath, ... }:
{
  # QEMU
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  services.qemuGuest.enable = true;
  hardware.enableRedistributableFirmware = false;

  # Storage
  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_blk"
  ];

  # AMD
  boot.kernelModules = [ "kvm-amd" ];

  # Bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
}
