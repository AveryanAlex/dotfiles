{ pkgs, ... }:
{
  home-manager.users.alex = {
    programs.eww = {
      enable = true;
      # package = pkgs.eww-wayland;
      configDir = ./configs;
    };
  };
}
