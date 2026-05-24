{ lib, ... }:
{
  persist.enable = lib.mkForce false;

  fileSystems."/" = {
    device = "/dev/alligator/root";
    fsType = "btrfs";
    options = [
      "discard=async"
      "compress=zstd"
      "subvol=@"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/alligator/root";
    fsType = "btrfs";
    neededForBoot = true;
    options = [
      "discard=async"
      "compress=zstd"
      "subvol=@home"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/alligator/root";
    fsType = "btrfs";
    neededForBoot = true;
    options = [
      "discard=async"
      "compress=zstd"
      "subvol=@nix"
    ];
  };

  fileSystems."/var/log" = {
    device = "/dev/alligator/root";
    fsType = "btrfs";
    options = [
      "discard=async"
      "compress=zstd"
      "subvol=@logs"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/FBC5-F521";
    fsType = "vfat";
  };

  swapDevices = [
    {
      device = "/dev/alligator/swap";
      discardPolicy = "both";
    }
  ];
}
