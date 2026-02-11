{
  hm.programs.zed-editor = {
    enable = true;
    extensions = [
      "opencode"
      "nix"
      "wakatime"
      "neocmake"
      "rainbow-csv"
      "toml"
      "xml"
      "java"
      "dockerfile"
      "typst"
      "latex"
      "git-firefly"
    ];
    userSettings = {
      autosave = "on_focus_change";

      buffer_font_family = "Monaspace Neon";
      buffer_font_features = {
        calt = true;
        ss01 = true;
        ss02 = true;
        ss03 = true;
        ss04 = true;
        ss05 = true;
        ss06 = true;
        ss07 = true;
        ss08 = true;
        ss09 = true;
        liga = true;
      };

      terminal = {
        font_family = "MesloLGS NF";
      };

      inlay_hints = {
        enabled = true;
      };
    };
  };

  hm.home.shellAliases.zed = "zeditor";
}
