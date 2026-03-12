{
  home-manager.users.alex = {
    programs.alacritty = {
      enable = true;
      settings = {
        window = {
          opacity = 0.97;
          padding = {
            x = 5;
            y = 7;
          };
        };
        font = {
          normal.family = "MesloLGS NF";
          size = 12.0;
        };
        colors = {
          primary = {
            background = "#EFF1F5";
            foreground = "#4C4F69";
            dim_foreground = "#4C4F69";
            bright_foreground = "#4C4F69";
          };
          cursor = {
            text = "#EFF1F5";
            cursor = "#DC8A78";
          };
          vi_mode_cursor = {
            text = "#EFF1F5";
            cursor = "#7287FD";
          };
          search = {
            matches = {
              foreground = "#EFF1F5";
              background = "#6C6F85";
            };
            focused_match = {
              foreground = "#EFF1F5";
              background = "#40A02B";
            };
          };
          footer_bar = {
            foreground = "#EFF1F5";
            background = "#6C6F85";
          };
          hints = {
            start = {
              foreground = "#EFF1F5";
              background = "#DF8E1D";
            };
            end = {
              foreground = "#EFF1F5";
              background = "#6C6F85";
            };
          };
          selection = {
            text = "#EFF1F5";
            background = "#DC8A78";
          };
          normal = {
            black = "#5C5F77";
            red = "#D20F39";
            green = "#40A02B";
            yellow = "#DF8E1D";
            blue = "#1E66F5";
            magenta = "#EA76CB";
            cyan = "#179299";
            white = "#ACB0BE";
          };
          bright = {
            black = "#6C6F85";
            red = "#D20F39";
            green = "#40A02B";
            yellow = "#DF8E1D";
            blue = "#1E66F5";
            magenta = "#EA76CB";
            cyan = "#179299";
            white = "#BCC0CC";
          };
          dim = {
            black = "#5C5F77";
            red = "#D20F39";
            green = "#40A02B";
            yellow = "#DF8E1D";
            blue = "#1E66F5";
            magenta = "#EA76CB";
            cyan = "#179299";
            white = "#ACB0BE";
          };
        };
        keyboard.bindings = [
          {
            key = "Return";
            mods = "Control|Shift";
            action = "SpawnNewInstance";
          }
        ];
      };
    };
  };
}
