{
  config,
  lib,
  ...
}:
{
  imports = [
    ./direnv.nix
    ./gpg
    ./linux.nix
    ./nethogs.nix
    # ./neovim
    ./tmux.nix
    ./tmux-auto.nix
    ./zellij.nix
    ./zoxide.nix
    ./zsh
  ];

  home-manager.users.alex.imports = [
    ../../../home/shell
    ../../../home/shell/heavy-tools.nix
  ]
  ++ lib.optional (config.networking.hostName != "lizard") ../../../home/shell/fastfetch.nix;
}
