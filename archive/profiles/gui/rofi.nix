{ pkgs, ... }:
{
  home-manager.users.alex = {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      plugins = [ pkgs.rofi-emoji ];
      terminal = "alacritty";
      extraConfig = {
        modi = "drun,run,ssh,filebrowser";
        show-icons = true;
        sorting-method = "fzf";
      };
    };
    wayland.windowManager.hyprland.extraConfig = ''
      bind=SUPER,D,exec,rofi -show drun
    '';
  };
}
