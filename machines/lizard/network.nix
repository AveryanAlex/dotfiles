let
  interface = "end0";
in
{
  systemd.network.networks = {
    "40-${interface}" = {
      name = "${interface}";
      networkConfig = {
        IPv6AcceptRA = false;
        DHCPServer = true;
      };
      dhcpServerConfig = {
        PoolOffset = 100;
        PoolSize = 50;
        DNS = "1.1.1.1";
      };
      dhcpServerStaticLeases = [
        {
          Address = "192.168.7.52";
          MACAddress = "00:18:a9:7a:d2:18";
        }
      ];
    };
  };

  networking = {
    nat = {
      externalInterface = interface;
      internalInterfaces = [
        interface
      ];
    };

    firewall = {
      interfaces.${interface}.allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [
        67
        546
      ]; # DHCP
      extraForwardRules = ''
        ip saddr 192.168.7.52 counter reject
      '';
    };

    defaultGateway = {
      address = "192.168.7.3";
      interface = interface;
    };

    interfaces = {
      "${interface}" = {
        ipv4 = {
          addresses = [
            {
              address = "192.168.7.1";
              prefixLength = 24;
            }
          ];
        };
      };
    };
  };
}
