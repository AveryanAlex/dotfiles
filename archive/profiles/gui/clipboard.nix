{
  pkgs,
  lib,
  ...
}:
{
  hm = {
    home.packages = [
      pkgs.cliphist
      pkgs.wl-clipboard
    ];
    wayland.windowManager = {
      hyprland.extraConfig = ''
        exec-once=wl-paste --type text --watch cliphist store
        exec-once=wl-paste --type image --watch cliphist store
        bind=SUPER,V,exec,cliphist list | rofi -dmenu | cliphist decode | wl-copy
      '';
      sway.config.keybindings = lib.mkOptionDefault {
        "Mod4+v" = "exec cliphist list | rofi -dmenu | cliphist decode | wl-copy";
      };
      sway.extraConfig = ''
        exec wl-paste --type text --watch cliphist store
        exec wl-paste --type image --watch cliphist store
      '';
    };
  };
}
