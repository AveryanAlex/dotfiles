{ pkgs, ... }:
{
  home-manager.users.alex = {
    xdg = {
      enable = true;
      cacheHome = /home/alex/.cache;
      configHome = /home/alex/.config;
      dataHome = /home/alex/.local/share;
      stateHome = /home/alex/.local/state;
    };

    home.packages = with pkgs; [
      xdg-utils
      xdg-user-dirs
    ];
  };
}
