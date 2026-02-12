{
  config,
  pkgs,
  lib,
  secrets,
  ...
}:
{
  age.secrets.bash-init = {
    file = "${secrets}/creds/bash-init.age";
    owner = "alex";
    group = "users";
  };

  home-manager.users.alex = {
    # Autostart zsh in interactive non-tty sessions
    programs.bash.enable = true;
    programs.bash.initExtra = ''
      source ${config.age.secrets.bash-init.path}
      if [[ "$(tty)" != /dev/tty* && $(ps --no-header --pid=$PPID --format=comm) != "zsh" && -z $BASH_EXECUTION_STRING ]]; then
        exec zsh
      fi
    '';

    # Beautiful cat
    programs.bat.enable = true;

    programs.atuin = {
      enable = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      flags = [ "--disable-up-arrow" ];
      daemon.enable = true;
      settings = {
        enter_accept = false;
        stats.common_prefix = [
          "sudo"
          "_"
        ];
        sync.records = true;
      };
    };

    programs.zsh = {
      enable = true;

      # history = {
      #   size = 30000;
      #   save = 30000;
      #   extended = true;
      #   path = "/home/alex/.local/state/zsh/history";
      # };

      dotDir = "/home/alex/.config/zsh";

      autosuggestion.enable = true;
      enableCompletion = true;
      enableVteIntegration = true;
      autocd = true;

      syntaxHighlighting.enable = true;

      shellAliases = {
        ip = "ip --color=auto";

        upd = "nh os switch";
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
  };

  environment.pathsToLink = [ "/share/zsh" ];
  persist.state.homeDirs = [ ".local/share/atuin" ];
}
