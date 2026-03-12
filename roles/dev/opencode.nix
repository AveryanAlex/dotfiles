{ pkgs, ... }:
let
  best = {
    model = "anthropic/claude-opus-4-6";
    variant = "max";
  };
  alt-best = {
    model = "openai/gpt-5.4";
    variant = "xhigh";
  };
  normal = {
    model = "anthropic/claude-opus-4-6";
    variant = "medium";
  };
  fast = normal;
  ohMyOpencodeVersion = "3.11.2";
  ohMyOpencodeConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/dev/assets/oh-my-opencode.schema.json";
    disabled_hooks = [
      "todo-continuation-enforcer"
    ];
    agents = {
      sisyphus = alt-best;
      sisyphus-junior = normal;
      hephaestus = {
        model = "openai/gpt-5.3-codex";
        variant = "medium";
      };
      oracle = alt-best;
      librarian.model = "anthropic/claude-sonnet-4-6";
      explore.model = "anthropic/claude-sonnet-4-6";
      multimodal-looker = {
        model = "openai/gpt-5.4";
        variant = "medium";
      };
      prometheus = alt-best;
      metis = best;
      momus = best;
      atlas = alt-best;
    };
    categories = {
      visual-engineering = best;
      ultrabrain = {
        model = "openai/gpt-5.3-codex";
        variant = "xhigh";
      };
      deep = {
        model = "openai/gpt-5.3-codex";
        variant = "high";
      };
      quick = fast;
      unspecified-low.model = fast;
      unspecified-high = {
        model = "openai/gpt-5.4";
        variant = "high";
      };
      writing.model = normal;
    };
  };
in
{
  hm.programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      enabled_providers = [
        "anthropic"
        "openai"
      ];
      plugin = [
        "opencode-wakatime"
        # "@mohak34/opencode-notifier@latest"
        "opencode-devcontainers"
        "cc-safety-net"
        "@simonwjackson/opencode-direnv"
        "opencode-beads"
        "oh-my-opencode@${ohMyOpencodeVersion}"
      ];
      permission = {
        bash = {
          "*" = "allow";
        };
      };
    };
  };

  hm.xdg.configFile."opencode/oh-my-opencode.json".text = builtins.toJSON ohMyOpencodeConfig;

  hm.home.packages = with pkgs; [
    # mcp-nixos TODO: re-add once fixed
    libnotify
    opencode-desktop
  ];
}
