{
  fileSystems."/boot" = {
    device = "/dev/vda2";
    fsType = "vfat";
  };

  fileSystems."/persist" = {
    device = "/dev/vda3";
    fsType = "ext4";
    options = [ "discard" ];
  };
}
