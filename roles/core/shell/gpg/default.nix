{ config, ... }:
{
  home-manager.users.alex.programs.gpg.homedir =
    "${config.home-manager.users.alex.xdg.dataHome}/gnupg";

  persist.state.homeDirs = [
    {
      directory = ".local/share/gnupg";
      mode = "u=rwx,g=,o=";
    }
  ];
}
