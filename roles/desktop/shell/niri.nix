{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  niri-pkgs = inputs.niri-flake.packages.${pkgs.system};
in
{
  imports = [ inputs.niri-flake.nixosModules.niri ];

  programs.niri = {
    enable = true;
    package = niri-pkgs.niri-unstable;
  };

  hm = {
    programs.niri.settings = {
      input = {
        keyboard = {
          xkb = {
            layout = "us,ru";
            options = "grp:caps_toggle,grp_led:caps";
          };
          track-layout = "window";
        };
        touchpad = {
          tap = true;
          click-method = "clickfinger";
        };
        focus-follows-mouse.enable = true;
      };

      layout = {
        gaps = 8;
        border = {
          enable = true;
          width = 2;
        };
      };

      binds =
        let
          spawn = cmd: {
            action.spawn = if builtins.isList cmd then cmd else [ cmd ];
          };
        in
        {
          # Terminal
          "Mod+Return" = spawn "alacritty";

          # Window management
          "Mod+Q".action.close-window = { };
          "Mod+F".action.fullscreen-window = { };
          "Mod+Shift+V".action.toggle-window-floating = { };

          # Focus (WASD)
          "Mod+A".action.focus-column-left = { };
          "Mod+D".action.focus-column-right = { };
          "Mod+W".action.focus-window-or-workspace-up = { };
          "Mod+S".action.focus-window-or-workspace-down = { };

          # Move (Shift+WASD)
          "Mod+Shift+A".action.move-column-left = { };
          "Mod+Shift+D".action.move-column-right = { };
          "Mod+Shift+W".action.move-window-up-or-to-workspace-up = { };
          "Mod+Shift+S".action.move-window-down-or-to-workspace-down = { };

          # Column management
          "Mod+E".action.consume-or-expel-window-left = { };
          "Mod+Shift+E".action.consume-or-expel-window-right = { };
          "Mod+C".action.center-column = { };
          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";

          # Overview
          "Mod+O".action.toggle-overview = { };

          # Lock screen (DMS handles actual lock via its keybinds)
          "Mod+L".action.do-screen-transition = { };

          # Screenshots
          "Print" = spawn [
            "sh"
            "-c"
            ''grim -g "$(slurp)" - | satty -f -''
          ];
          "Shift+Print" = spawn [
            "sh"
            "-c"
            "grim - | satty -f -"
          ];
        }
        // (lib.listToAttrs (
          map (n: {
            name = "Mod+${toString n}";
            value.action.focus-workspace = n;
          }) (lib.range 1 9)
        ))
        // (lib.listToAttrs (
          map (n: {
            name = "Mod+Shift+${toString n}";
            value.action.move-window-to-workspace = n;
          }) (lib.range 1 9)
        ));

      workspaces = lib.listToAttrs (
        map (n: {
          name = toString n;
          value = { };
        }) (lib.range 1 9)
      );
    };
  };
}
