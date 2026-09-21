{
  config,
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
    programs.bash = {
      enable = true;
      initExtra = ''
        source ${config.age.secrets.bash-init.path}
        if [[ "$(tty)" != /dev/tty* && $(ps --no-header --pid=$PPID --format=comm) != "zsh" && -z $BASH_EXECUTION_STRING ]]; then
          exec zsh
          # if [[ -z "$ZELLIJ" && -z "$SSH_CONNECTION" && ("$TERM" == "alacritty" || "$TERM_PROGRAM" == "WezTerm") ]]; then
          #   exec zellij
          # else
          #   exec zsh
          # fi
        fi
      '';
    };

    programs.atuin.enableBashIntegration = true;

    programs.zsh = {
      dotDir = "${config.home-manager.users.alex.xdg.configHome}/zsh";
      enableVteIntegration = true;
      shellAliases = {
        ip = "ip --color=auto";
        upd = "nh os switch";
      };
    };
  };

  environment.pathsToLink = [ "/share/zsh" ];
  persist.state.homeDirs = [ ".local/share/atuin" ];
}
