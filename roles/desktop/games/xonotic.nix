{ pkgs, ... }:
{
  home-manager.users.alex = {
    home.packages = [ pkgs.xonotic ];
  };

  persist.state.homeDirs = [ ".xonotic" ];
}
