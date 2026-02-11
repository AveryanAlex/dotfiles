{
  fileSystems."/persist" = {
    device = "/dev/ferret/data";
    fsType = "ext4";
    options = [ "discard" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/16E2-004F";
    fsType = "vfat";
  };
}
