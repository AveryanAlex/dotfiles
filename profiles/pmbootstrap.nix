{
  pkgs,
  lib,
  ...
}:
{
  home-manager.users.alex = {
    home.packages = [
      pkgs.pmbootstrap
    ];
  };

  persist.state.homeDirs = [ ".local/var/pmbootstrap" ];
}
