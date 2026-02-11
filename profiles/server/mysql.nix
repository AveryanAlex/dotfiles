{ pkgs, ... }:
{
  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
    settings = {
      mysqld = {
        max_connections = 512;
      };
    };
  };

  persist.state.dirs = [
    {
      directory = "/var/lib/mysql";
      user = "mysql";
      group = "mysql";
      mode = "u=rwx,g=,o=";
    }
  ];
}
