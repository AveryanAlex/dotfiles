{ pkgs, ... }:
let
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
  gpt-54-low = gpt-54 // {
    variant = "low";
  };
  gemini-pro = {
    model = "github-copilot/gemini-3.1-pro-preview";
  };
  gemini-pro-medium = gemini-pro // {
    variant = "medium";
  };

  simplifySrc = pkgs.fetchFromGitHub {
    owner = "brianlovin";
    repo = "agent-config";
    rev = "009b50c90c4a106e0c94565c4a5afd93343218c9";
    hash = "sha256-WnxdSacRir2CvZpYX2I9zl1c7XRHBwoNEvoGJDtavr4=";
  };
  agentBrowserSrc = pkgs.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "agent-browser";
    rev = "8cfba1752d794e67856dfca67cd424a7a776b0d3";
    hash = "sha256-OIarkXZfK18quKvoKIeotv7kdvDC1buKY/OfKuHQ0e8=";
  };

  ohMyOpencodeVersion = "3.12.3";
  ohMyOpencodeConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";
    agents = {
      # main orchestrator
      sisyphus = gpt-54-high;
      # main subagent coder
      sisyphus-junior = gpt-54-medium;
      # deep autonomous coder
      hephaestus = gpt-54-high;
      # plan writer
      prometheus = gpt-54-high;
      # architecture consultant
      oracle = gpt-54-high;
      # code reviewer
      momus = gpt-54-high;
      # plan gap analyzer
      metis = gpt-54-high;
      # plan executor
      atlas = gpt-54-high;
      # codebase explorer
      explore = gpt-54-low;
      # docs/OSS research
      librarian = gpt-54-low;
      # vision/screenshots
      multimodal-looker = gemini-pro-medium;
    };
    categories = {
      # frontend, UI/UX, design
      visual-engineering = gemini-pro-medium;
      # hard logic, complex architecture
      ultrabrain = gpt-54-xhigh;
      # autonomous research + execution
      deep = gpt-54-high;
      # creative approaches
      artistry = gemini-pro-medium;
      # trivial tasks
      quick = gpt-54-low;
      # general tasks, low effort
      unspecified-low = gpt-54-medium;
      # general tasks, high effort
      unspecified-high = gpt-54-high;
      # documentation, prose
      writing = gpt-54-medium;
    };
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
        "github-copilot"
        # "anthropic"
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
        # "opencode-beads"
        "oh-my-opencode@${ohMyOpencodeVersion}"
      ];
      agent = {
        # explore.disable = true;
        # general.disable = true;
      };
      model = "openai/gpt-5.4";
      small_model = "github-copilot/gpt-5-mini";
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
    # mcp-nixos TODO: re-add once fixed
    libnotify
    opencode-desktop
  ];
}
