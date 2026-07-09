{ config, inputs, lib, ... }:
{
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

  services.flatpak = {
    packages = [
      "com.obsproject.Studio"
      "org.gnome.Papers"
      "org.libreoffice.LibreOffice"
      "com.brave.Browser"
      "org.signal.Signal"
    ];

    update.auto = {
      enable = true;
      onCalendar = "daily";
    };

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

  systemd.services = {
    flatpak-managed-install = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };

    flatpak-managed-install-timer = lib.mkIf config.services.flatpak.update.auto.enable {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
    };
  };

  persist.state.dirs = [ "/var/lib/flatpak" ];
  persist.state.homeDirs = [ ".var/app" ];
}
