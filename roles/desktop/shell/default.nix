{ pkgs, ... }:
{
  imports = [
    ./niri.nix
    ./dms.nix
  ];

  # Display manager: greetd + tuigreet with auto-login
  services.greetd = {
    enable = true;
    restart = false; # prevent auto-login re-triggering on greetd restart
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
        user = "greeter";
      };
      initial_session = {
        command = "niri-session";
        user = "alex";
      };
    };
  };

  # SSH agent
  programs.ssh.startAgent = true;

  # XDG portals
  environment.pathsToLink = [
    "/share/xdg-desktop-portal"
    "/share/applications"
  ];

  xdg.portal = {
    xdgOpenUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config.niri = {
      default = [
        "gnome"
        "gtk"
      ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "niri" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "niri" ];
    };
  };

  # dconf (needed by various apps)
  programs.dconf.enable = true;

  # Valent (KDE Connect replacement)
  networking.firewall = rec {
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      }
    ];
    allowedUDPPortRanges = allowedTCPPortRanges;
  };

  hm = {
    # Secrets
    services.gnome-keyring.enable = true;
    services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3;

    # Packages
    home.packages = with pkgs; [
      # clipboard
      wl-clipboard

      # screenshots
      grim
      slurp
      satty

      # phone integration
      valent

      # wireless diagnostics
      iw

      # GTK3 theme for DMS dark/light toggle
      adw-gtk3
    ];

    # Cursor
    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

    # GTK theme (DMS Matugen manages color overrides at runtime)
    gtk = {
      enable = true;
      theme = {
        name = "adw-gtk3-dark";
        package = pkgs.adw-gtk3;
      };
      iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
      };
    };

    # Qt theme
    qt = {
      enable = true;
      style.name = "adwaita-dark";
    };
  };

  # Keyring persistence
  persist.state.homeDirs = [ ".local/share/keyrings" ];
}
