{
  pkgs,
  lib,
  ...
}: {
  nixcfg.gnome.enable = true;
  services.xserver = {
    xkb.layout = "us,ru";
    xkb.options = "grp:caps_toggle,grp_led:caps";
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
    };
  };

  services.displayManager.autoLogin.user = "alex";
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  environment.pathsToLink = ["/share/xdg-desktop-portal" "/share/applications"];

  xdg.portal = {
    # extraPortals = [pkgs.xdg-desktop-portal-gnome];
    xdgOpenUsePortal = true;
  };

  i18n.inputMethod.type = "ibus";

  security.wrappers = {
    nethogs = {
      source = "${pkgs.nethogs}/bin/nethogs";
      capabilities = "cap_net_admin=ep cap_net_raw=ep";
      owner = "root";
      group = "root";
      permissions = "u+rx,g+x,o+x";
    };
  };

  environment.variables = {
    GI_TYPELIB_PATH = "/run/current-system/sw/lib/girepository-1.0";
  };
  environment.systemPackages = with pkgs; [
    nethogs
    libgtop
  ];

  hm = {
    # home.packages = with pkgs; [
    #   # screenshots
    #   grim
    #   slurp

    #   # icons
    #   adwaita-icon-theme
    #   libsForQt5.breeze-icons

    #   # keyring
    #   seahorse
    #   gcr
    # ];

    home.file.".config/gtk-3.0/bookmarks".text = ''
      file:///home/alex/projects Projects
      file:///tank Tank
      file:///home/alex/Documents
      file:///home/alex/Pictures
      file:///home/alex/Downloads
    '';

    home.packages = with pkgs; [
      iw
      wl-clipboard
      # gtop
    ];

    services.gpg-agent.pinentryPackage = pkgs.pinentry-gnome3;
    services.gnome-keyring.enable = true;

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        accent-color = "teal";
        color-scheme = "prefer-dark";
        clock-show-seconds = true;
        show-battery-percentage = true;
      };
      "org/gnome/mutter" = {
        experimental-features = ["scale-monitor-framebuffer" "x11-randr-fractional-scaling"];
        edge-tiling = true;
        dynamic-workspaces = false;
      };
      "org/gnome/desktop/peripherals/touchpad" = {
        tap-to-click = true;
        click-method = "areas";
      };
      "org/gnome/desktop/wm/keybindings" =
        {
          activate-window-menu = [];
          begin-move = [];
          begin-resize = [];
          close = ["<Super>q"];
          cycle-group = [];
          cycle-group-backward = [];
          cycle-panels = [];
          cycle-panels-backward = [];
          cycle-windows = [];
          cycle-windows-backward = [];
          maximize = [];
          minimize = [];
          move-to-monitor-down = [];
          move-to-monitor-left = [];
          move-to-monitor-right = [];
          move-to-monitor-up = [];
          move-to-workspace-down = [];
          move-to-workspace-last = [];
          move-to-workspace-left = [];
          move-to-workspace-right = [];
          move-to-workspace-up = [];
          panel-run-dialog = [];
          switch-applications = [];
          switch-applications-backward = [];
          switch-group = [];
          switch-group-backward = [];
          switch-input-source = [];
          switch-input-source-backward = [];
          switch-panels = [];
          switch-panels-backward = [];
          switch-to-workspace-down = [];
          switch-to-workspace-last = [];
          switch-to-workspace-left = [];
          switch-to-workspace-right = [];
          switch-to-workspace-up = [];
          toggle-maximized = ["<Super>f"];
          unmaximize = [];
        }
        // (lib.listToAttrs (map (v: {
          name = "move-to-workspace-${builtins.toString v}";
          value = ["<Super><Shift>${builtins.toString v}"];
        }) [1 2 3 4 5 6 7 8 9]))
        // (lib.listToAttrs (map (v: {
          name = "switch-to-workspace-${builtins.toString v}";
          value = ["<Super>${builtins.toString v}"];
        }) [1 2 3 4 5 6 7 8 9]));
      "org/gnome/desktop/wm/preferences" = {
        focus-mode = "sloppy";
        num-workspaces = 9;
      };
      "org/gnome/shell/keybindings" =
        {
          focus-active-notification = [];
          shift-overview-down = [];
          shift-overview-up = [];
          show-screen-recording-ui = [];
          toggle-application-view = [];
          toggle-message-tray = [];
          toggle-quick-settings = [];
        }
        // (lib.listToAttrs (map (v: {
          name = "open-new-window-application-${builtins.toString v}";
          value = [];
        }) [1 2 3 4 5 6 7 8 9]))
        // (lib.listToAttrs (map (v: {
          name = "switch-to-application-${builtins.toString v}";
          value = [];
        }) [1 2 3 4 5 6 7 8 9]));
      "org/gnome/mutter/keybindings" = {
        cancel-input-capture = [];
        switch-monitor = ["XF86Display"];
        toggle-tiled-left = [];
        toggle-tiled-right = [];
      };
      "org/gnome/mutter/wayland/keybindings" = {
        restore-shortcuts = [];
      };
      "org/gnome/shell/extensions/forge" = {
        window-gap-hidden-on-single = true;
        dnd-center-layout = "swap";
      };
      "org/gnome/shell/extensions/forge/keybindings" = {
        window-focus-down = ["<Super>s"];
        window-focus-left = ["<Super>a"];
        window-focus-right = ["<Super>d"];
        window-focus-up = ["<Super>w"];
        window-move-down = ["<Shift><Super>s"];
        window-move-left = ["<Shift><Super>a"];
        window-move-right = ["<Shift><Super>d"];
        window-move-up = ["<Shift><Super>w"];
        window-swap-last-active = [];
        window-gap-size-decrease = [];
        window-gap-size-increase = [];
        window-resize-bottom-decrease = [];
        window-resize-bottom-increase = [];
        window-resize-left-decrease = [];
        window-resize-left-increase = [];
        window-resize-right-decrease = [];
        window-resize-right-increase = [];
        window-resize-top-decrease = [];
        window-resize-top-increase = [];
        window-snap-center = [];
        window-snap-one-third-left = [];
        window-snap-one-third-right = [];
        window-snap-two-third-left = [];
        window-snap-two-third-right = [];
        window-swap-down = [];
        window-swap-left = [];
        window-swap-right = [];
        window-swap-up = [];
        window-toggle-always-float = [];
        window-toggle-float = [];
        workspace-active-tile-toggle = [];
        con-split-horizontal = [];
        con-split-layout-toggle = ["<Super>e"];
        con-split-vertical = [];
        con-stacked-layout-toggle = [];
        con-tabbed-layout-toggle = [];
        con-tabbed-showtab-decoration-toggle = [];
        focus-border-toggle = [];
        prefs-open = [];
        prefs-tiling-toggle = [];
      };
      "org/gnome/settings-daemon/plugins/media-keys" = {
        help = [];
        logout = [];
        magnifier = [];
        magnifier-zoom-in = [];
        magnifier-zoom-out = [];
        screenreader = [];
        screensaver = [];
      };
      "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = ["/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"];
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "Terminal";
        binding = "<Super>Return";
        command = "alacritty";
      };
      "org/gnome/shell/extensions/space-bar/behavior" = {
        toggle-overview = false;
      };
      "org/gnome/shell/extensions/space-bar/shortcuts" = {
        back-and-forth = true;
        enable-activate-workspace-shortcuts = true;
        open-menu = [];
        activate-empty-key = [];
        activate-previous-key = [];
      };
      "org/gnome/shell/extensions/space-bar/appearance" = {
        workspaces-bar-padding = 4;
        workspace-margin = 0;
      };
      "org/gnome/shell/extensions/astra-monitor" = {
        storage-main = "name-hamster-data";
      };
      # "org/gnome/desktop/wm/preferences" = {
      #   button-layout = "appmenu:minimize,maximize,close";
      # };
      # "org/gnome/desktop/interface" = {
      #   font-antialiasing = "rgba";
      # };
      # "org/gnome/shell" = {
      # enabled-extensions = ["dash-to-dock@micxgx.gmail.com"];
      # favorite-apps = [
      #   "org.gnome.Console.desktop"
      #   "org.gnome.Calendar.desktop"
      #   "thunderbird.desktop"
      #   "org.gnome.Nautilus.desktop"
      #   "firefox.desktop"
      # ];
      # };
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

    programs.gnome-shell = {
      enable = true;
      extensions = with pkgs.gnomeExtensions; [
        # {
        #   package = pkgs.gnomeExtensions.forge;
        # }
        # {
        #   package = pkgs.gnomeExtensions.space-bar;
        # }
        {
          package = blur-my-shell;
        }
        {
          package = forge;
        }
        {
          package = astra-monitor;
        }
        {
          package = caffeine;
        }
      ];
    };
  };

  persist.state.homeDirs = [".local/share/keyrings"];

  programs.dconf.enable = true;

  environment.gnome.excludePackages = with pkgs; [
    geary
    gnome-calendar
    epiphany
    gnome-contacts
    totem
    gnome-tour
  ];

  # programs.gnome-disks.enable = false;
}
