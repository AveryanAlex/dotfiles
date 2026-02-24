{ pkgs, ... }:
{
  hm.programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      # model = "synthetic/hf:moonshotai/Kimi-K2.5";
      enabled_providers = [
        "synthetic"
        "openai"
      ];
      provider.synthetic.options.baseURL = "https://code.fob.wtf/syn/openai/v1";
      plugin = [
        "opencode-wakatime"
        "@mohak34/opencode-notifier@latest"
        "opencode-devcontainers"
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

  hm.home.packages = with pkgs; [
    # mcp-nixos TODO: re-add once fixed
    libnotify
  ];
}
