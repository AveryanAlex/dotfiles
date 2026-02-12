{
  lib,
  pkgs,
  config,
  ...
}:
{
  home-manager.users.alex = {
    programs.bash.enable = true;
    programs.bash.profileExtra = ''
      if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
        sway
      fi
    '';

    home.packages = [ pkgs.pulseaudio ];

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;

      extraSessionCommands = ''
        export NIXOS_OZONE_WL=1

        export _JAVA_AWT_WM_NONREPARENTING=1
        export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
        export QT_QPA_PLATFORM=wayland
      '';

      config = {
        input = {
          "*" = {
            xkb_layout = "us,ru";
            xkb_options = "grp:caps_toggle,grp_led:caps";
          };
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
            dwt = "disabled";
          };
        };
        bars = [ ];
        focus = {
          followMouse = "always";
          # mouseWarping = "container";
        };
        gaps = {
          inner = 5;
          outer = 5;
          smartBorders = "on";
          smartGaps = true;
        };
        workspaceAutoBackAndForth = true;

        bindkeysToCode = true;
        keybindings =
          let
            cfg = config.home-manager.users.alex.wayland.windowManager.sway.config;
          in
          lib.mkOptionDefault {
            "${cfg.modifier}+q" = "kill";

            # TODO: clipboard history
            # "${cfg.modifier}+h" = "exec clipman pick -t rofi";
            # TODO: run in terminal
            # "${cfg.modifier}+Shift+d" = "exec rofi -show run -run-shell-command \'{terminal} -e zsh -ic \"{cmd} && read\"\'";

            "Mod4+m" = "exec rofi -show emoji";

            # "XF86AudioMute" = "exec pactl set-sink-mute @DEFAULT_SINK@ toggle";
            # "XF86AudioMicMute" = "exec pactl set-source-mute @DEFAULT_SOURCE@ toggle";
            # "XF86AudioRaiseVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ +5%";
            # "XF86AudioLowerVolume" = "exec pactl set-sink-volume @DEFAULT_SINK@ -5%";

            # "XF86MonBrightnessDown" = "exec brillo -u 10000 -U 10";
            # "XF86MonBrightnessUp" = "exec brillo -u 10000 -A 10";

            "Print" =
              ''exec grim -g "$(slurp -d)" - | tee "Pictures/Screenshots/$(date --rfc-3339=seconds).png" | wl-copy -t image/png'';
            "Shift+Print" =
              ''exec grim - | tee "Pictures/Screenshots/$(date --rfc-3339=seconds).png" | wl-copy -t image/png'';
            # TODO: screenshot focused window
            # "Mod1+Print" = ''exec ${pkgs.grim}/bin/grim -g "$(${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -j '.. | select(.type?) | select(.focused).rect | "\(.x),\(.y) \(.width)x\(.height)"')" - | tee "Pictures/Screenshots/$(date --rfc-3339=seconds).png" | wl-copy -t image/png'';
            # TODO: setup flameshot
          };
        terminal = "alacritty";
        menu = "rofi -show drun";
        modifier = "Mod4"; # Super
      };
      extraConfig = ''
        exec swayidle
        exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        exec systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
        exec ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
        exec ${pkgs.xdg-desktop-portal-gtk}/libexec/xdg-desktop-portal-gtk

        # STYLING
        default_border pixel 1
        smart_borders on

        for_window [shell="xdg_shell"] title_format "%title (%app_id)"
        for_window [shell="x_wayland"] title_format "%class - %title"
      '';
    };
  };
}
