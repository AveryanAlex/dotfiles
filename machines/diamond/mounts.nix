{
  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/758c4bcb-aee8-4908-a746-5e633ed55040";
    options = [ "discard" ];
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/F113-58F4";
    fsType = "vfat";
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/67158e62-70e0-4403-92d6-9ce7b36f072a"; }
  ];
}
