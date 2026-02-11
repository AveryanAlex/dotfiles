{
  services.borgbackup.repos.qfzwufeu = {
    quota = "150G";
    path = "/var/lib/borgbackup/qfzwufeu";
    authorizedKeysAppendOnly = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAm0keIU4qYLB0yb1sRv068glIUZqBVmbGpZPc1MDBFo"
    ];
  };

  fileSystems."/var/lib/borgbackup" = {
    device = "UUID=bcfa404a-68de-4a25-9fb0-4e972c8f9423";
    fsType = "btrfs";
    options = [
      "compress=none"
      "noatime"
      "subvol=@borgbackup"
    ];
  };

  networking.firewall.extraInputRules = ''
    ip6 saddr 200:571e:effc:1361:696b:35b5:e577:5a63 tcp dport 22 accept
  '';
}
