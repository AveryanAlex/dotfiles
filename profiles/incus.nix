let
  bridge = "incusbr0";
  gateway = "10.77.0.1";
  noProxyBridge = "inoprbr0";
  noProxyGateway = "10.78.0.1";
in
{
  virtualisation.incus = {
    enable = true;

    preseed = {
      storage_pools = [
        {
          name = "default";
          driver = "dir";
          config.source = "/var/lib/incus/storage-pools/default";
        }
      ];

      profiles = [
        {
          name = "default";
          config."boot.autostart" = "true";
          devices = {
            eth0 = {
              name = "eth0";
              type = "nic";
              nictype = "bridged";
              parent = bridge;
            };

            root = {
              path = "/";
              pool = "default";
              type = "disk";
            };
          };
        }
      ];
    };
  };

  users.users.alex.extraGroups = [ "incus-admin" ];

  networking.tproxy.forward.${bridge} = { };

  networking = {
    bridges.${bridge}.interfaces = [ ];
    bridges.${noProxyBridge}.interfaces = [ ];
    nat.internalInterfaces = [
      bridge
      noProxyBridge
    ];
    interfaces.${bridge}.ipv4.addresses = [
      {
        address = gateway;
        prefixLength = 24;
      }
    ];
    interfaces.${noProxyBridge}.ipv4.addresses = [
      {
        address = noProxyGateway;
        prefixLength = 24;
      }
    ];

    firewall.interfaces.${bridge}.allowedUDPPorts = [ 67 ];
    firewall.interfaces.${noProxyBridge}.allowedUDPPorts = [ 67 ];
  };

  systemd.network.networks."40-${bridge}" = {
    networkConfig = {
      IPv6AcceptRA = false;
      ConfigureWithoutCarrier = true;
      DHCPServer = true;
    };
    linkConfig.RequiredForOnline = false;
    dhcpServerConfig = {
      PoolOffset = 100;
      PoolSize = 50;
      EmitDNS = true;
      DNS = "1.1.1.1";
    };
  };

  systemd.network.networks."40-${noProxyBridge}" = {
    networkConfig = {
      IPv6AcceptRA = false;
      ConfigureWithoutCarrier = true;
      DHCPServer = true;
    };
    linkConfig.RequiredForOnline = false;
    dhcpServerConfig = {
      PoolOffset = 100;
      PoolSize = 50;
      EmitDNS = true;
      DNS = "1.1.1.1";
    };
  };

  persist.state.dirs = [ "/var/lib/incus" ];
}
