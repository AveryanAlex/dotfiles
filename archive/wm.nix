{pkgs, ...}: {
  hm = {
    home.packages = with pkgs; [
      # screenshots
      grim
      slurp

      # icons
      adwaita-icon-theme
      libsForQt5.breeze-icons

      # keyring
      seahorse
      gcr
    ];

    services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3;
    services.gnome-keyring.enable = true;

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };
    };

    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 16;
    };

    gtk = {
      enable = true;

      theme = {
        name = "Adwaita-dark";
        package = pkgs.gnome-themes-extra;
      };

      iconTheme = {
        package = pkgs.adwaita-icon-theme;
        name = "Adwaita";
      };
    };

    qt = {
      enable = true;
      style.name = "adwaita-dark";
    };
  };

  persist.state.homeDirs = [".local/share/keyrings"];

  programs.dconf.enable = true;
}
