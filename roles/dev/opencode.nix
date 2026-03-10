{ pkgs, ... }:
let
  ohMyOpencodeVersion = "3.11.2";
  ohMyOpencodeConfig = {
    "$schema" =
      "https://raw.githubusercontent.com/code-yeongyu/oh-my-opencode/dev/assets/oh-my-opencode.schema.json";
    agents = {
      sisyphus = {
        model = "anthropic/claude-opus-4-6";
        variant = "max";
      };
      hephaestus = {
        model = "openai/gpt-5.3-codex";
        variant = "medium";
      };
      oracle = {
        model = "openai/gpt-5.4";
        variant = "high";
      };
      librarian.model = "anthropic/claude-sonnet-4-6";
      explore.model = "anthropic/claude-sonnet-4-6";
      "multimodal-looker" = {
        model = "openai/gpt-5.4";
        variant = "medium";
      };
      prometheus = {
        model = "anthropic/claude-opus-4-6";
        variant = "max";
      };
      metis = {
        model = "anthropic/claude-opus-4-6";
        variant = "max";
      };
      momus = {
        model = "openai/gpt-5.4";
        variant = "xhigh";
      };
      atlas.model = "anthropic/claude-sonnet-4-6";
    };
    categories = {
      "visual-engineering" = {
        model = "anthropic/claude-opus-4-6";
        variant = "max";
      };
      ultrabrain = {
        model = "openai/gpt-5.3-codex";
        variant = "xhigh";
      };
      deep = {
        model = "openai/gpt-5.3-codex";
        variant = "medium";
      };
      quick.model = "anthropic/claude-sonnet-4-6";
      "unspecified-low".model = "anthropic/claude-sonnet-4-6";
      "unspecified-high" = {
        model = "openai/gpt-5.4";
        variant = "high";
      };
      writing.model = "anthropic/claude-sonnet-4-6";
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
          "*" = "ask";
          "cat *" = "allow";
          "head *" = "allow";
          "tail *" = "allow";
          "grep *" = "allow";
          "rg *" = "allow";
          "ls *" = "allow";
          "find *" = "allow";
          # "sed *" = "allow";
          # "awk *" = "allow";
          "sort *" = "allow";
          "uniq *" = "allow";
          "wc *" = "allow";
          # "cut *" = "allow";
          # "tr *" = "allow";
          "jq *" = "allow";
          # "yq *" = "allow";
          "curl *" = "allow";
          "wget *" = "allow";
          "git diff *" = "allow";
          "nix *" = "allow";
          "tree *" = "allow";
          # "bat *" = "allow";
          "eza *" = "allow";
          "echo *" = "allow";
          "ping *" = "allow";
          "which *" = "allow";
          "whereis *" = "allow";
          "type *" = "allow";
          "file *" = "allow";
          "stat *" = "allow";
          "readlink *" = "allow";
          "realpath *" = "allow";
          "dirname *" = "allow";
          "basename *" = "allow";
          "ps *" = "allow";
          # "top *" = "allow";
          # "htop *" = "allow";
          # "btop *" = "allow";
        };
      };
    };
  };

  hm.xdg.configFile."opencode/oh-my-opencode.json".text = builtins.toJSON ohMyOpencodeConfig;

  hm.home.packages = with pkgs; [
    # mcp-nixos TODO: re-add once fixed
    libnotify
  ];
}
