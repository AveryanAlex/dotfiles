{
  inputs,
  lib,
  ...
}:
{
  imports =
    with inputs.self.nixosModules.modules;
    [
      persist
      nebula-averyan
    ]
    ++ (with inputs.self.nixosModules.profiles; [
      agenix
      boot
      console
      dhcp
      dns
      filesystems
      gui.gnome
      hosts
      persist
      logs
      monitoring
      mining
      nebula-averyan
      nftables
      nix
      nur
      polkit
      ssh-server
      sudo
      timezone
      unfree
      zram

      family.users
      family.home
      family.firefox
      family.userdirs
      family.misc-f
    ]);

  i18n.defaultLocale = "ru_RU.UTF-8";
  persist.username = lib.mkForce "olga";
}
