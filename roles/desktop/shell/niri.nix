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

  # niri-flake NixOS module provides:
  #   - programs.niri.enable (session registration, xdg-utils)
  #   - hardware.graphics
  #   - xdg.portal (portal-gnome + niri configPackages)
  #   - security.polkit + polkit-kde-agent service
  #   - services.gnome.gnome-keyring
  #   - security.pam.services.swaylock
  #   - programs.dconf (mkDefault)
  #   - fonts.enableDefaultPackages (mkDefault)
  #   - home-manager.sharedModules with niri-flake config module
  programs.niri = {
    enable = true;
    package = niri-pkgs.niri-unstable;
  };

  environment.systemPackages = [ niri-pkgs.xwayland-satellite-unstable ];

  hm = {
    programs.niri.settings = {
      prefer-no-csd = true;

      input = {
        keyboard = {
          xkb = {
            layout = "us,ru";
            options = "grp:caps_toggle,grp_led:caps";
          };
          numlock = true;
          track-layout = "window";
        };
        touchpad = {
          tap = true;
          tap-button-map = "left-right-middle";
          click-method = "button-areas";
          middle-emulation = false;
        };
        warp-mouse-to-focus.enable = true;
        focus-follows-mouse.enable = true;
        workspace-auto-back-and-forth = true;
      };

      layout = {
        gaps = 4;
        border = {
          enable = true;
          width = 2;
        };
        focus-ring.width = 2;
      };

      gestures.dnd-edge-view-scroll = {
        delay-ms = 70;
        max-speed = 5000;
      };

      window-rules = [
        {
          geometry-corner-radius = {
            top-left = 12.0;
            top-right = 12.0;
            bottom-right = 12.0;
            bottom-left = 12.0;
          };
          clip-to-geometry = true;
          tiled-state = true;
          draw-border-with-background = false;
        }
      ];

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
          "Mod+F".action.maximize-column = { };
          "Mod+Shift+F".action.fullscreen-window = { };
          "Mod+Shift+V".action.toggle-window-floating = { };

          # Focus (WASZ)
          "Mod+A".action.focus-column-left = { };
          "Mod+S".action.focus-column-right = { };
          "Mod+W".action.focus-window-or-workspace-up = { };
          "Mod+Z".action.focus-window-or-workspace-down = { };

          # Focus (mouse wheel)
          "Mod+WheelScrollUp".action.focus-column-left = { };
          "Mod+WheelScrollDown".action.focus-column-right = { };
          "Mod+WheelScrollLeft".action.focus-column-left = { };
          "Mod+WheelScrollRight".action.focus-column-right = { };

          # Move (Shift+WASZ)
          "Mod+Shift+A".action.move-column-left = { };
          "Mod+Shift+S".action.move-column-right = { };
          "Mod+Shift+WheelScrollUp".action.move-column-left = { };
          "Mod+Shift+WheelScrollDown".action.move-column-right = { };
          "Mod+Shift+WheelScrollLeft".action.move-column-left = { };
          "Mod+Shift+WheelScrollRight".action.move-column-right = { };
          "Mod+Shift+W".action.move-window-up-or-to-workspace-up = { };
          "Mod+Shift+Z".action.move-window-down-or-to-workspace-down = { };

          # Column management
          "Mod+E".action.consume-or-expel-window-left = { };
          "Mod+Shift+E".action.consume-or-expel-window-right = { };
          "Mod+C".action.center-column = { };
          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";
          "Mod+Shift+Minus".action.set-window-height = "-10%";
          "Mod+Shift+Equal".action.set-window-height = "+10%";
          "Mod+Shift+BackSpace".action.switch-preset-window-height = { };

          # Overview
          "Mod+X".action.toggle-overview = { };

          # Lock screen
          "Mod+L".action.do-screen-transition = { };

          # Screenshots
          "Print".action.screenshot = { };
          "Shift+Print".action.screenshot-screen = { };
          "Mod+Print".action.screenshot-window = { };

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
