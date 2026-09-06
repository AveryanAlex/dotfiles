{ lib, ... }:
{
  users.users.i2pd = {
    isSystemUser = true;
    group = "i2pd";
    uid = 150;
  };

  users.groups.i2pd.gid = 150;

  services.i2pd = {
    enable = true;
    settings = {
      host = "95.165.105.90";
      port = 17283;
      bandwidth = 2048;

      ntcp2 = {
        enabled = true;
        port = 15728;
        published = true;
      };

      meshnets.yggdrasil = true;
    };
  };

  systemd.services.i2pd.serviceConfig = {
    DynamicUser = lib.mkForce false;
    MemoryMax = "512M";
  };

  networking.firewall.allowedTCPPorts = [
    17283
    15728
  ];
  networking.firewall.allowedUDPPorts = [ 17283 ];

  persist.state.dirs = [
    {
      directory = "/var/lib/i2pd";
      user = "i2pd";
      group = "i2pd";
      mode = "u=rwx,g=,o=";
    }
  ];
}
