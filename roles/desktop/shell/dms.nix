{ inputs, pkgs, ... }:
let
  dms-shell = inputs.dms.packages.${pkgs.system}.default;
in
{
  imports = [ inputs.dms.nixosModules.dank-material-shell ];

  # DMS NixOS module provides:
  #   - services.power-profiles-daemon
  #   - services.accounts-daemon
  #   - quickshell in environment.systemPackages
  programs.dank-material-shell.enable = true;

  # DMS provides its own polkit agent integration, so keep niri-flake's
  # agent disabled while DMS is active.
  systemd.user.services.niri-flake-polkit.enable = false;

  hm = {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms.homeModules.niri
    ];

    home.packages = [ pkgs.adw-gtk3 ];

    # DMS Matugen manages runtime GTK color overrides, so keep the baseline
    # GTK theme and GTK4 ownership with the rest of the DMS integration.
    gtk = {
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      gtk4 = {
        theme = null;
        extraCss = "";
      };
    };

    programs.niri.settings = {
      layout = {
        background-color = "transparent";

        focus-ring = {
          active.color = "#42a5f5";
          inactive.color = "#8c9199";
          urgent.color = "#f2b8b5";
        };

        border = {
          active.color = "#42a5f5";
          inactive.color = "#8c9199";
          urgent.color = "#f2b8b5";
        };

        shadow.color = "#00000070";

        tab-indicator = {
          active.color = "#42a5f5";
          inactive.color = "#8c9199";
          urgent.color = "#f2b8b5";
        };

        insert-hint.display.color = "#42a5f580";
      };

    };

    programs.niri.settings.binds =
      let
        dms-ipc = args: {
          action.spawn = [
            "qs"
            "ipc"
            "-p"
            "${dms-shell}/share/quickshell/dms"
            "--any-display"
            "--newest"
            "call"
          ]
          ++ args;
        };
      in
      {
        # DMS shell controls and widgets
        "Mod+Space" = dms-ipc [
          "powermenu"
          "toggle"
        ];
        "Mod+N" = dms-ipc [
          "notifications"
          "toggle"
        ];
        "Mod+Comma" = dms-ipc [
          "settings"
          "toggle"
        ];
        "Mod+P" = dms-ipc [
          "notepad"
          "toggle"
        ];
        "Mod+V" = dms-ipc [
          "clipboard"
          "toggle"
        ];
        "Mod+X" = dms-ipc [
          "spotlight"
          "toggle"
        ];
        "Mod+M" = dms-ipc [
          "processlist"
          "toggle"
        ];
        "Super+Alt+L" = dms-ipc [
          "lock"
          "lock"
        ];
        "Mod+Alt+N" =
          (dms-ipc [
            "night"
            "toggle"
          ])
          // {
            allow-when-locked = true;
          };

        # DMS OSD controls
        "XF86AudioRaiseVolume" =
          (dms-ipc [
            "audio"
            "increment"
            "3"
          ])
          // {
            allow-when-locked = true;
          };
        "XF86AudioLowerVolume" =
          (dms-ipc [
            "audio"
            "decrement"
            "3"
          ])
          // {
            allow-when-locked = true;
          };
        "XF86AudioMute" =
          (dms-ipc [
            "audio"
            "mute"
          ])
          // {
            allow-when-locked = true;
          };
        "XF86AudioMicMute" =
          (dms-ipc [
            "audio"
            "micmute"
          ])
          // {
            allow-when-locked = true;
          };
        "XF86MonBrightnessUp" =
          (dms-ipc [
            "brightness"
            "increment"
            "5"
            ""
          ])
          // {
            allow-when-locked = true;
          };
        "XF86MonBrightnessDown" =
          (dms-ipc [
            "brightness"
            "decrement"
            "5"
            ""
          ])
          // {
            allow-when-locked = true;
          };
      };

    programs.dank-material-shell = {
      enable = true;

      # Systemd user service: auto-restarts on crash, restarts on config change
      systemd.enable = true;

      # DMS keybinds are defined manually here for full control.
      # Do not enable enableKeybinds — it injects a hardcoded non-customizable set.
      niri.includes.enable = false;
    };
  };
}
