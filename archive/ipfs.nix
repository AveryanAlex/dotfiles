{inputs, ...}: {
  imports = [
    inputs.self.nixosModules.profiles.server.ipfs
    inputs.self.nixosModules.profiles.server.ipfs-cluster
  ];
  persist.state.dirs = [
    {
      directory = "/var/lib/ipfs";
      user = "ipfs";
      group = "ipfs";
      mode = "u=rwx,g=rx,o=rx";
    }
  ];
  fileSystems."/var/lib/ipfs/blocks" = {
    device = "UUID=bcfa404a-68de-4a25-9fb0-4e972c8f9423";
    fsType = "btrfs";
    options = ["compress=zstd:7" "noatime" "subvol=@ipfs"];
  };
}
