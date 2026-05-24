{ pkgs, ... }:
let
  gpt-55 = {
    model = "openai/gpt-5.5";
  };
  gpt-55-xhigh = gpt-55 // {
    variant = "xhigh";
  };
  gpt-55-high = gpt-55 // {
    variant = "high";
  };
  gpt-55-medium = gpt-55 // {
    variant = "medium";
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
  gpt-54-mini = {
    model = "openai/gpt-5.4-mini";
  };

  gemini-pro = {
    model = "github-copilot/gemini-3.1-pro-preview";
  };
  gemini-pro-high = gemini-pro // {
    variant = "high";
  };

  ohMyOpenagentVersion = "3.17.6";

  ohMyOpenagentConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";
    default_run_agent = "sisyphus";
    hashline_edit = false;
    agents = {
      # main orchestrator
      sisyphus = gpt-54-xhigh;
      # main subagent coder
      sisyphus-junior = gpt-54-medium;
      # deep autonomous coder
      hephaestus = gpt-54-high;
      # plan writer
      prometheus = gpt-55-xhigh;
      # architecture consultant
      oracle = gpt-55-xhigh;
      # plan critic
      momus = gpt-55-xhigh;
      # plan gap analyzer
      metis = gpt-55-xhigh;
      # plan executor
      atlas = gpt-54-high;
      # codebase explorer
      explore = gpt-54-mini;
      # docs/OSS research
      librarian = gpt-54-mini;
      # vision/screenshots
      multimodal-looker = gemini-pro-high;
      # plan = gpt-high;
      # build = gpt-high;
    };
    categories = {
      visual-engineering = gpt-54-medium;
      ultrabrain = gpt-55-xhigh;
      deep = gpt-54-high;
      artistry = gemini-pro-high;
      quick = gpt-54-mini;
      unspecified-low = gpt-54-medium;
      unspecified-high = gpt-54-high;
      writing = gpt-54-medium;
    };
    git_master = {
      commit_footer = false;
      include_co_authored_by = false;
      git_env_prefix = "GIT_MASTER=1";
    };
  };
in
{
  hm.programs.opencode = {
    enable = true;
    # enableMcpIntegration = true;
    # settings = {
    #   enabled_providers = [
    #     "openai"
    #     "anthropic"
    #     "github-copilot"
    #   ];
    #   compaction = {
    #     auto = true;
    #     # prune = false;
    #   };
    #   lsp = true;
    #   plugin = [
    #     "opencode-wakatime"
    #     "superpowers@git+https://github.com/obra/superpowers.git"
    #     # "opencode-devcontainers"
    #     # "cc-safety-net"
    #     # "@simonwjackson/opencode-direnv"
    #     # "oh-my-openagent@${ohMyOpenagentVersion}"
    #   ];
    #   agent = {
    #     # explore.disable = true;
    #     # general.disable = true;
    #   };
    #   model = gpt-54.model;
    #   # small_model = "github-copilot/gpt-5-mini";
    #   small_model = gpt-54-mini.model;
    #   provider.anthropic.options.baseURL = "https://claude.machka.dev/v1";
    #   provider.openai.models."gpt-5.5".limit = {
    #     context = 400000;
    #     input = 272000;
    #     output = 128000;
    #   };
    #   permission = {
    #     bash = {
    #       # "*" = "ask";
    #     };
    #     external_directory."*" = "allow";
    #   };
    # };
    # skills = {
    #   # simplify = "${simplifySrc}/skills/simplify";
    #   # agent-browser = "${agentBrowserSrc}/skills/agent-browser";
    # };
    # context = ./opencode-rules.md;
  };

  # hm.xdg.configFile."opencode/oh-my-openagent.json".text = builtins.toJSON ohMyOpenagentConfig;

  hm.home.sessionVariables = {
    OMO_SEND_ANONYMOUS_TELEMETRY = "0";
    OMO_DISABLE_POSTHOG = "1";
    OPENCODE_EXPERIMENTAL = "true";
    RTK_TELEMETRY_DISABLED = "1";
  };

  hm.home.packages = with pkgs; [
    # mcp-nixos
    ast-grep
    ripgrep
    agent-browser
    playwright-test
    playwright-mcp
    opencode-desktop
  ];
}
