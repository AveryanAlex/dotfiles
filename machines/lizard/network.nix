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
      # IP-camera (192.168.7.52, MAC 00:18:a9:7a:d2:18) outbound block.
      # Disabled because tproxy intercepts traffic before the forward chain
      # runs, so this rule wouldn't fire anyway. If the camera needs to be
      # quarantined again, re-add the block in prerouting (before tproxy)
      # or as a SRC-IP-CIDR REJECT rule in mihomo.
      # extraForwardRules = ''
      #   ip saddr 192.168.7.52 counter reject
      # '';
    };

    # Mirror whale: proxy lizard's own outbound traffic and forward LAN
    # clients (DHCP'd into 192.168.7.100-149) through mihomo too. RFC1918 +
    # multicast + `fib daddr type local` are already in tproxy's bypass set,
    # so LAN-internal hops (camera RTSP, MQTT, HASS UI, DHCP/SSH to lizard)
    # stay direct without extra config.
    tproxy.output.enable = true;
    tproxy.forward.${interface} = { };

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
