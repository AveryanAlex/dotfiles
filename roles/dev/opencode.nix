{ pkgs, ... }:
let
  opus = {
    model = "anthropic/claude-opus-4-6";
  };
  opus-max = opus // {
    variant = "max";
  };
  opus-high = opus // {
    variant = "high";
  };

  gpt = {
    model = "openai/gpt-5.4";
  };
  gpt-xhigh = gpt // {
    variant = "xhigh";
  };
  gpt-high = gpt // {
    variant = "high";
  };
  gpt-medium = gpt // {
    variant = "medium";
  };

  gpt-codex = {
    model = "openai/gpt-5.3-codex";
  };
  gpt-codex-medium = gpt-codex // {
    variant = "medium";
  };

  gpt-mini = {
    model = "openai/gpt-5.4-mini";
  };

  gemini-pro = {
    model = "github-copilot/gemini-3.1-pro-preview";
  };
  gemini-pro-high = gemini-pro // {
    variant = "high";
  };

  ohMyOpencodePath = "/home/alex/projects/code-yeongyu/oh-my-openagent";

  ohMyOpencodeConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";
    agents = {
      # main orchestrator
      sisyphus = opus-max;
      # main subagent coder
      # sisyphus-junior = gpt-medium;
      # deep autonomous coder
      hephaestus = gpt-codex-medium;
      # plan writer
      prometheus = opus-max;
      # architecture consultant
      oracle = gpt-high;
      # code reviewer
      momus = gpt-xhigh;
      # plan gap analyzer
      metis = opus-max;
      # plan executor
      atlas = opus-high;
      # codebase explorer
      explore = gpt-mini;
      # docs/OSS research
      librarian = gpt-mini;
      # vision/screenshots
      multimodal-looker = gpt-medium;
    };
    categories = {
      # frontend, UI/UX, design
      visual-engineering = gemini-pro-high;
      # hard logic, complex architecture
      ultrabrain = gpt-xhigh;
      # autonomous research + execution
      deep = gpt-codex-medium;
      # creative approaches
      artistry = gemini-pro-high;
      # trivial tasks
      quick = gpt-mini;
      # general tasks, low effort
      unspecified-low = gpt-codex-medium;
      # general tasks, high effort
      unspecified-high = opus-high;
      # documentation, prose
      writing = gpt-medium;
    };
    disabled_hooks = [
      "model-fallback"
      "session-recovery"
    ];
    git_master = {
      commit_footer = false;
      include_co_authored_by = false;
    };
    tmux = {
      enabled = true;
      layout = "main-vertical";
      main_pane_size = 60;
      main_pane_min_width = 120;
      agent_pane_min_width = 40;
    };
  };
in
{
  hm.programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      enabled_providers = [
        "openai"
        "anthropic"
        "github-copilot"
      ];
      compaction = {
        auto = true;
        prune = false;
      };
      plugin = [
        "opencode-wakatime"
        "opencode-devcontainers"
        "cc-safety-net"
        "@simonwjackson/opencode-direnv"
        "file://${ohMyOpencodePath}"
      ];
      agent = {
        # explore.disable = true;
        # general.disable = true;
      };
      model = opus.model;
      # small_model = "github-copilot/gpt-5-mini";
      small_model = gpt-mini.model;
      provider.anthropic.options.baseURL = "https://litellm.averyan.ru/v1";
      permission = {
        bash = {
          # "*" = "ask";
        };
        external_directory."*" = "allow";
      };
    };
    skills = {
      # simplify = "${simplifySrc}/skills/simplify";
      # agent-browser = "${agentBrowserSrc}/skills/agent-browser";
    };
    rules = builtins.readFile ./opencode-rules.md;
  };

  hm.xdg.configFile."opencode/oh-my-opencode.json".text = builtins.toJSON ohMyOpencodeConfig;

  hm.home.packages = with pkgs; [
    mcp-nixos
    opencode-desktop
  ];
}
