{ config, secrets, ... }:
{
  age.secrets.radicale-password = {
    file = "${secrets}/accounts/radicale.age";
    owner = "radicale";
    group = "radicale";
  };

  services.radicale = {
    enable = true;
    settings = {
      server.hosts = [ "[::]:5232" ];
      auth = {
        type = "htpasswd";
        htpasswd_filename = config.age.secrets.radicale-password.path;
        htpasswd_encryption = "bcrypt";
      };
    };
  };

  users.users.radicale.uid = 984;
  users.groups.radicale.gid = 984;

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 5232 ];
  persist.state.dirs = [
    {
      directory = "/var/lib/radicale/collections";
      user = "radicale";
      group = "radicale";
      mode = "u=rwx,g=rx,o=";
    }
  ];
}
