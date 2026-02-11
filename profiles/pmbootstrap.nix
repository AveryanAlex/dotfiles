{
  pkgs,
  lib,
  ...
}:
{
  home-manager.users.alex = {
    home.packages = [
      # pmbootstrap
    ];
  };

  persist.state.homeDirs = [ ".local/var/pmbootstrap" ];
}
