{
  pkgs,
  lib,
  ...
}:
{
  home-manager.users.alex = {
    home.packages = [
      pkgs.swayosd
    ];
    wayland.windowManager = {
      hyprland.extraConfig = ''
        exec-once=swayosd-server

        bindle=, XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise --max-volume 150
        bindle=, XF86AudioLowerVolume, exec, swayosd-client --output-volume lower --max-volume 150

        bindle=SHIFT, XF86AudioRaiseVolume, exec, swayosd-client --input-volume raise
        bindle=SHIFT, XF86AudioLowerVolume, exec, swayosd-client --input-volume lower

        bind=, XF86AudioMute, exec, swayosd-client --output-volume mute-toggle
        bind=, XF86AudioMicMute, exec, swayosd --input-volume mute-toggle

        binde=, XF86MonBrightnessUp, exec, swayosd-client --brightness raise
        binde=, XF86MonBrightnessDown, exec, swayosd-client --brightness lower
      '';

      sway.config.keybindings = lib.mkOptionDefault {
        "XF86AudioRaiseVolume" = "exec swayosd-client --output-volume raise --max-volume 150";
        "XF86AudioLowerVolume" = "exec swayosd-client --output-volume lower --max-volume 150";

        "Shift+XF86AudioRaiseVolume" = "exec swayosd-client --input-volume raise";
        "Shift+XF86AudioLowerVolume" = "exec swayosd-client --input-volume lower";

        "XF86AudioMute" = "exec swayosd-client --output-volume mute-toggle";
        "XF86AudioMicMute" = "exec swayosd-client --input-volume mute-toggle";

        "XF86MonBrightnessUp" = "exec swayosd-client --brightness raise";
        "XF86MonBrightnessDown" = "exec swayosd-client --brightness lower";
      };
      sway.extraConfig = ''
        exec swayosd-server
      '';
    };
  };
}
