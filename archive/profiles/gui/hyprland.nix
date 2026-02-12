{
  pkgs,
  config,
  ...
}:
{
  programs.hyprland.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.regreet.enable = true;
  services.greetd.settings = {
    initial_session = {
      command = "${config.hm.wayland.windowManager.hyprland.finalPackage}/bin/Hyprland";
      user = "alex";
    };
  };

  hm = {
    home.packages = with pkgs; [
      grimblast
    ];

    wayland.windowManager.hyprland = {
      enable = true;

      plugins = with pkgs.hyprlandPlugins; [
        # hyprspace
        # hyprexpo
        # hyprgrass
      ];

      settings = {
        "$mod" = "SUPER";
        bind =
          let
            hyprgamemode = pkgs.writeShellScript "hyprgamemode.sh" ''
              HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')
              if [ "$HYPRGAMEMODE" = 1 ] ; then
                hyprctl --batch "\
                  keyword animations:enabled 0;\
                  keyword decoration:drop_shadow 0;\
                  keyword decoration:blur:enabled 0;\
                  keyword general:gaps_in 0;\
                  keyword general:gaps_out 0;\
                  keyword general:border_size 1;\
                  keyword decoration:rounding 0"
                exit
              fi
              hyprctl reload
            '';
          in
          [
            ", Print, exec, grimblast copy area"
            "$mod, Q, killactive,"
            "$mod, F, fullscreen, 0"
            "SUPERSHIFT, E, exit,"
            "$mod, return, exec, alacritty"
            "$mod, space, togglefloating,"
            "$mod, left, movefocus, l"
            "$mod, right, movefocus, r"
            "$mod, up, movefocus, u"
            "$mod, down, movefocus, d"
            "SUPERSHIFT, left, movewindow, l"
            "SUPERSHIFT, right, movewindow, r"
            "SUPERSHIFT, up, movewindow, u"
            "SUPERSHIFT, down, movewindow, d"
            "$mod, F1, exec, ${hyprgamemode}"
            # "$mod, TAB, overview:toggle,"
            # "$mod, grave, hyprexpo:expo, toggle"
          ]
          ++ (builtins.concatLists (
            builtins.genList (
              x:
              let
                ws =
                  let
                    c = (x + 1) / 10;
                  in
                  builtins.toString (x + 1 - (c * 10));
              in
              [
                "$mod, ${ws}, workspace, ${toString (x + 1)}"
                "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
              ]
            ) 10
          ));
        # bindm = ["ALT, mouse:272, movewindow"];

        monitor = ",preferred,auto,1";

        general = {
          border_size = 2;
          gaps_out = 10;
          resize_on_border = true;
          hover_icon_on_border = false;
        };

        decoration = {
          rounding = 7;
          inactive_opacity = 0.95;
          blur = {
            enabled = true;
            size = 3;
          };
        };

        input = {
          kb_layout = "us,ru";
          kb_options = "grp:caps_toggle,grp_led:caps";
          numlock_by_default = true;
          scroll_method = "2fg";
          emulate_discrete_scroll = 0;

          touchpad = {
            disable_while_typing = false;
            natural_scroll = true;
          };
        };

        gestures = {
          workspace_swipe = true;
          workspace_swipe_cancel_ratio = 0.15;
        };

        # "plugin:touch_gestures" = {
        #   sensitivity = 2.0;
        #   workspace_swipe_fingers = 3;
        #   workspace_swipe_edge = "d";
        #   long_press_delay = 400;
        #   edge_margin = 10;
        #   experimental.send_cancel = true;
        # };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          # render_ahead_of_time = true;
          middle_click_paste = false;
        };
      };

      extraConfig = ''
        exec-once=${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
      '';
    };
  };
}
