{
  lib,
  pkgs,
  ...
}:
{
  programs.zsh = {
    enable = true;

    autosuggestion.enable = true;
    enableCompletion = true;
    autocd = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      claude = "claude --dangerously-skip-permissions";
      whale-hermes = ''ssh -t whale 'sudo machinectl shell root@hermes-alex /run/current-system/sw/bin/bash -lc "exec /run/current-system/sw/bin/hermes"'';
      # sudo = "echo Permission denied:";
      # "_" = "/run/wrappers/bin/sudo";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "zsh-interactive-cd"
        "git-auto-fetch"
        "git"
      ];
    };

    initContent = ''
      # Gas Town shell integration
      # [[ -f "$HOME/.config/gastown/shell-hook.sh" ]] && source "$HOME/.config/gastown/shell-hook.sh"

      # if [[ -o interactive ]] && [[ -n "$SSH_CONNECTION" ]] && [[ -z "$TMUX" ]]; then
      #   exec tmux-auto ssh
      # fi
    '';

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./p10k-config;
        file = "p10k.zsh";
      }
    ];
  };
}
