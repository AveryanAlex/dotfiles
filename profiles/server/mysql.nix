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

  systemd.services.mysql.serviceConfig.MemoryMax = "2G";

  persist.state.dirs = [
    {
      directory = "/var/lib/mysql";
      user = "mysql";
      group = "mysql";
      mode = "u=rwx,g=,o=";
    }
  ];
}
