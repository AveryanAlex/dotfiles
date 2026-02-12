{
  services.tor = {
    enable = true;
    openFirewall = true;
    relay = {
      enable = true;
      role = "private-bridge";
    };
    settings = {
      # ContactInfo = "alex@averyan.ru";
      # Nickname = "AveryanalexHawk";
      ORPort = 9628;
      ServerTransportListenAddr = "obfs4 [::]:4372";
      ControlPort = 9051;
      BandWidthRate = "2 MBytes";
    };
  };
  networking.firewall.allowedTCPPorts = [ 4372 ];

  services.prometheus.exporters.tor = {
    enable = true;
  };
  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 9130 ];

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
