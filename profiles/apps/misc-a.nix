{ pkgs, ... }:
{
  hm = {
    home.packages = with pkgs; [
      # Communication
      # element-desktop
      # schildichat-desktop # electron matrix client
      # fractal-next # gtk matrix client
      # webcord-vencord # discord client
      # telegram-desktop # telegram client
      ayugram-desktop

      # Creativity
      # libsForQt5.kdenlive # video editor
      mediainfo # idk but kdenlive depends on it
      # gimp # image editor
      # krita # painting program

      # Finance
      # monero-gui # anonymous crypto

      # Notes
      # joplin-desktop # markdown notes
      obsidian
      # openboard # qt whiteboard
      # rnote # gtk whiteboard
      # xournalpp

      # LaTeX
      # texstudio
      pandoc
      texlive.combined.scheme-full
      hunspell
      hunspellDicts.en-us
      hunspellDicts.ru-ru

      # File viewers
      # gthumb # gtk image viewer
      evince # gnome document viewer
      papers
      # f3d # simple 3d viewer

      # 3D modeling
      # openscad
      # freecad
      # blender
      # gmsh
      # calculix
      # elmerfem
      # prusa-slicer
      # stable.orca-slicer
      # kicad-unstable
      # python311Packages.kicad

      # Etc
      # tor-browser-bundle-bin # anonymous browsing
      libreoffice-fresh # office
      # octaveFull # math software
      # kgraphviewer # graphviz viewer
      # stellarium # planetarium
      # kleopatra # gpg gui
      # spek # audio file spectrogram
      # kmplot
      helvum
      # gyroflow
      # betaflight-configurator
      # brave
      chromium
      gamescope
      # distrobox
      # ocrmypdf
      # remmina
      # openfortivpn
      waypipe
      ptyxis
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "org.gnome.Evince.desktop";
        "text/html" = "com.brave.Browser.desktop";
        "x-scheme-handler/http" = "com.brave.Browser.desktop";
        "x-scheme-handler/https" = "com.brave.Browser.desktop";
        # "image/jpeg" = "org.gnome.gThumb.desktop";
      };
    };

    # services.kdeconnect.enable = true;

    programs.obs-studio.enable = true;
  };

  # nixpkgs.config.permittedInsecurePackages = [
  #   "electron-22.3.27"
  # ];

  persist.state.homeDirs = [
    # ".config/Element"
    # ".config/WebCord"
    # ".local/share/TelegramDesktop"
    ".config/obs-studio"

    # "Monero"
    # ".bitmonero"
    # ".config/monero-project"

    # ".config/Joplin"
    # ".config/joplin-desktop"
    # ".local/share/OpenBoard"
    # ".config/xournalpp"
    # ".config/obsidian"

    # ".local/share/tor-browser"

    # ".config/PrusaSlicer"

    # ".config/kicad"
    # ".local/share/kicad"
    # ".config/BraveSoftware"
  ];
}
