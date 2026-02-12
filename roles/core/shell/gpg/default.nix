{ config, ... }:
{
  hm = {
    services.gpg-agent = {
      enable = true;
      # enableSshSupport = true;
    };

    programs.gpg = {
      enable = true;
      homedir = "${config.home-manager.users.alex.xdg.dataHome}/gnupg";
      mutableKeys = false;
      mutableTrust = false;
      publicKeys = [
        {
          source = ./averyanalex.asc;
          trust = 5;
        }
        {
          source = ./cofob.asc;
          trust = 4;
        }
        {
          source = ./qubes.asc;
          trust = 4;
        }
      ];
    };
  };

  persist.state.homeDirs = [
    {
      directory = ".local/share/gnupg";
      mode = "u=rwx,g=,o=";
    }
  ];
}
