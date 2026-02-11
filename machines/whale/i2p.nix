{
  services.i2pd = {
    enable = true;
    port = 17283;
    address = "95.165.105.90";

    bandwidth = 2048;

    ntcp2 = {
      enable = true;
      port = 15728;
      published = true;
    };

    yggdrasil.enable = true;
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
