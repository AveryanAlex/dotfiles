{
  services.tor = {
    enable = true;
    openFirewall = true;
    relay = {
      # enable = true;
      role = "private-bridge";
    };
    settings = {
      ContactInfo = "alex@averyan.ru";
      Nickname = "AveryanalexWhale";
      ORPort = 9628;
      ServerTransportListenAddr = "obfs4 [::]:4372";
      ControlPort = 9051;
      BandWidthRate = "2 MBytes";
      UseBridges = true;
      Bridge = [
        "[21b:321:3243:ecb6:a4cf:289c:c0f1:d6eb]:16728"
        "[21f:5234:5548:31e5:a334:854b:5752:f4fc]:9770"
        "[224:6723:7ae0:5655:e600:51c9:4300:a2fb]:9001"
      ];
    };
  };
  networking.firewall.allowedTCPPorts = [ 4372 ];

  services.snowflake-proxy.enable = true;
  systemd.services.snowflake-proxy.serviceConfig.MemoryMax = "256M";

  persist.state.dirs = [
    {
      directory = "/var/lib/tor";
      user = "tor";
      group = "tor";
      mode = "u=rwx,g=,o=";
    }
  ];
}
