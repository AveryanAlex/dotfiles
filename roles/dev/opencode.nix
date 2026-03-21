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
  omoSlimSrc = pkgs.fetchFromGitHub {
    owner = "alvinunreal";
    repo = "oh-my-opencode-slim";
    rev = "115bbac7e3cc76ec4cb20b51fe4c38bf3065b3a8"; # v0.8.3
    hash = "sha256-ftRtXNnuEJvzNgSHR37X9ggwWMRTbZIFc0VOm4Hd4XE=";
  };

  ohMyOpencodeSlimVersion = "0.8.3";
  superpowersVersion = "bf40c3813ad3e39cf22af85dd20589696e4a5e76";
  ohMyOpencodeSlimConfig = {
    "$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json";
    preset = "alex";
    fallback = {
      enabled = false;
    };
    presets = {
      alex = {
        orchestrator = gpt-54-high;
        oracle = gpt-54-xhigh;
        librarian = gpt-54-medium;
        explorer = gpt-54-medium;
        designer = gemini-pro-medium;
        fixer = gpt-54-medium;
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
        # "opencode-beads"
        "oh-my-opencode-slim@${ohMyOpencodeSlimVersion}"
        "superpowers@git+https://github.com/AveryanAlex/superpowers.git#${superpowersVersion}"
      ];
      agent = {
        explore.disable = true;
        general.disable = true;
      };
      permission = {
        bash = {
          "*" = "allow";
        };
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
    # mcp-nixos TODO: re-add once fixed
    libnotify
    opencode-desktop
  ];
}
