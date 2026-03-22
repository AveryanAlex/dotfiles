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
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
        user = "greeter";
      };
      initial_session = {
        command = "niri-session";
        user = "alex";
      };
    };
  };

  # SSH agent (disable gcr-ssh-agent from gnome-keyring to avoid conflict)
  programs.ssh.startAgent = true;
  services.gnome.gcr-ssh-agent.enable = false;

  # XDG portals: niri-flake handles portal-gnome and configPackages automatically.
  # We only set xdgOpenUsePortal and pathsToLink here.
  environment.pathsToLink = [
    "/share/xdg-desktop-portal"
    "/share/applications"
  ];
  xdg.portal.xdgOpenUsePortal = true;

  # dconf (also set by niri-flake via mkDefault, kept explicit for other apps)
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
    # gnome-keyring: also enabled by niri-flake NixOS module, kept explicit for clarity
    services.gnome-keyring.enable = true;
    services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3;
    services.wl-clip-persist = {
      enable = true;
      clipboardType = "regular";
    };

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

    ];

    # Cursor
    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

    gtk = {
      enable = true;
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
