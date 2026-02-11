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

      language_models = {
        openai_compatible = {
          Synthetic = {
            api_url = "https://code.fob.wtf/syn/openai/v1";
            available_models = [
              {
                name = "hf:moonshotai/Kimi-K2.5";
                max_tokens = 256000;
                max_output_tokens = 32000;
                max_completion_tokens = 200000;
                capabilities = {
                  tools = true;
                  images = true;
                  parallel_tool_calls = true;
                  prompt_cache_key = true;
                  chat_completions = true;
                };
              }
            ];
          };
        };
      };

      agent = {
        default_model = {
          provider = "Synthetic";
          model = "hf:moonshotai/Kimi-K2.5";
        };
        favorite_models = [ ];
        model_parameters = [ ];
      };
    };
  };

  hm.home.shellAliases.zed = "zeditor";
}
