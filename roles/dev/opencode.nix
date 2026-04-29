{ pkgs, ... }:
let
  gpt = {
    model = "openai/gpt-5.4";
  };
  gpt-high = gpt // {
    variant = "high";
  };
  gpt-xhigh = gpt // {
    variant = "xhigh";
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

  allowAll = {
    skills = [ "*" ];
    mcps = [ "*" ];
  };

  ohMyOpencodeSlimVersion = "1.0.1";

  ohMyOpencodeSlimConfig = {
    "$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json";
    preset = "alex";
    presets = {
      alex = {
        orchestrator = gpt-xhigh // allowAll;
        oracle = gpt-xhigh // allowAll;
        librarian = gpt-mini;
        explorer = gpt-mini;
        designer = gemini-pro-high // allowAll;
        fixer = gpt-high // allowAll;
      };
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
        # "cc-safety-net"
        "@simonwjackson/opencode-direnv"
        "oh-my-opencode-slim@${ohMyOpencodeSlimVersion}"
      ];
      agent = {
        explore.disable = true;
        general.disable = true;
      };
      model = gpt.model;
      # small_model = "github-copilot/gpt-5-mini";
      small_model = gpt-mini.model;
      provider.anthropic.options.baseURL = "https://claude.machka.dev/v1";
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

  hm.xdg.configFile."opencode/oh-my-opencode-slim.json".text = builtins.toJSON ohMyOpencodeSlimConfig;

  hm.home.packages = with pkgs; [
    mcp-nixos
    opencode-desktop
  ];
}
