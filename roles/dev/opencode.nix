{ pkgs, ... }:
let
  claude = {
    model = "anthropic/claude-opus-4-6";
  };
  claude-max = claude // {
    variant = "max";
  };
  claude-high = claude // {
    variant = "high";
  };
  gpt-54 = {
    model = "openai/gpt-5.4";
  };
  gpt-54-xhigh = gpt-54 // {
    variant = "xhigh";
  };
  gpt-54-high = gpt-54 // {
    variant = "high";
  };
  gpt-54-medium = gpt-54 // {
    variant = "medium";
  };
  gpt-53codex = {
    model = "openai/gpt-5.3-codex";
  };
  gpt-53codex-high = gpt-53codex // {
    variant = "high";
  };
  gpt-53codex-xhigh = gpt-53codex // {
    variant = "xhigh";
  };
  gpt-53codex-medium = gpt-53codex // {
    variant = "medium";
  };
  gemini-pro = {
    model = "github-copilot/gemini-3.1-pro-preview";
  };

  ohMyOpencodeVersion = "3.11.2";
  ohMyOpencodeConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/dev/assets/oh-my-opencode.schema.json";
    disabled_hooks = [
      "todo-continuation-enforcer"
    ];
    agents = {
      # main orchastrator
      sisyphus = claude-max;
      # main subagent coder
      sisyphus-junior = gpt-53codex-high;
      # deep autonomous coder
      hephaestus = gpt-53codex-high;
      # plan writer
      prometheus = claude-max;
      # architecture consultant
      oracle = gpt-54-xhigh;
      # code reviewer
      momus = gpt-54-high;
      # plan gap analyzer
      metis = claude-max;
      # plan executor
      atlas = gpt-54-high;
      # codebase explorer
      explore = gpt-53codex-medium;
      # docs/oss research
      librarian = gpt-53codex-medium;
      # vision/screenshots
      multimodal-looker = gpt-54-medium;
    };
    categories = {
      # frontend, UI/UX, design, animation
      visual-engineering = gemini-pro;
      # hard logic, complex architecture
      ultrabrain = gpt-53codex-xhigh;
      # autonomous research + execution
      deep = gpt-53codex-high;
      # creative, unconventional approaches
      artistry = gemini-pro;
      # trivial tasks, typo fixes
      quick = gpt-53codex-medium;
      # general tasks, low effort
      unspecified-low = claude-high;
      # general tasks, high effort
      unspecified-high = gpt-54-high;
      # documentation, prose, technical writing
      writing = gpt-53codex-medium;
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
        "github-copilot"
      ];
      compaction = {
        auto = true;
        prune = false;
      };
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
