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

  fileSystems."/home/alex/.var/app/com.valvesoftware.Steam" = {
    device = "/dev/alligator/secondary";
    fsType = "btrfs";
    options = [
      "discard=async"
      "compress=zstd"
      "subvol=@steam"
    ];
  };

  fileSystems."/home/alex/.var/app/com.usebottles.bottles" = {
    device = "/dev/alligator/secondary";
    fsType = "btrfs";
    options = [
      "discard=async"
      "compress=zstd"
      "subvol=@bottles"
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
