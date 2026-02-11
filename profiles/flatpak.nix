{ inputs, ... }:
{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  services.flatpak = {
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
      {
        name = "flathub-beta";
        location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      }
    ];

    overrides = {
      global = {
        # Context.sockets = ["wayland" "!x11" "!fallback-x11"];

        Environment = {
          # XCURSOR_PATH = "/run/host/user-share/icons:/run/host/share/icons";
          # GTK_THEME = "Adwaita:dark";
        };
      };

      "org.onlyoffice.desktopeditors".Context.sockets = [ "x11" ];
      "org.signal.Signal".Environment.SIGNAL_PASSWORD_STORE = "gnome-libsecret";
    };
  };

  services.flatpak.enable = true;
  services.dbus.enable = true;
  persist.state.dirs = [ "/var/lib/flatpak" ];
  persist.state.homeDirs = [ ".var/app" ];
}
