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
            background = "#ffffff";
            foreground = "#1a1a1a";
          };
          normal = {
            black = "#1a1a1a";
            red = "#d73a49";
            green = "#22863a";
            yellow = "#b08800";
            blue = "#0366d6";
            magenta = "#6f42c1";
            cyan = "#032f62";
            white = "#ffffff";
          };
          bright = {
            black = "#586069";
            red = "#cb2431";
            green = "#28a745";
            yellow = "#dbab09";
            blue = "#2188ff";
            magenta = "#8a63d2";
            cyan = "#044289";
            white = "#fafbfc";
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
