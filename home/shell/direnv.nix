{ pkgs, ... }:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config.whitelist.prefix = [
      "~/gt"
      "~/.local/share/opencode/worktree"
    ];
  };

  home.packages = [ pkgs.devenv ];
}
