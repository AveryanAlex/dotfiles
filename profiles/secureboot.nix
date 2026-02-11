{
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  boot.loader.systemd-boot.enable = lib.mkForce false;

  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  environment.systemPackages = [
    pkgs.sbctl
  ];

  persist.state.dirs = [ "/etc/secureboot" ];
}
