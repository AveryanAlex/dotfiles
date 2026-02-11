{ config, ... }:
{
  services.deluge = {
    enable = true;
    user = "alex";
    group = "users";
    declarative = true;
    config = {
      download_location = "/tank/dwnl/";
    };
    web = {
      enable = true;
      port = 8112;
      openFirewall = true;
    };
    authFile = "/var/lib/deluge/auth";
    # authFile = config.age.secrets.account-deluge.path;
    openFirewall = true;
  };

  # age.secrets.account-deluge = {
  #   file = ../../secrets/accounts/deluge.age;
  #   owner = "alex";
  #   group = "users";
  #   mode = "770";
  #   symlink = false;
  # };

  persist.state.dirs = [
    {
      directory = "/var/lib/deluge";
      user = "alex";
      group = "users";
      mode = "u=rwx,g=rwx,o=";
    }
  ];
}
