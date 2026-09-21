{ config, ... }:
let
  bridge = "incusbr0";
  gateway = "10.77.0.1";
  noProxyBridge = "inoprbr0";
  noProxyGateway = "10.78.0.1";
  vpnBridge = "incusvpn0";
  vpnGateway = "10.79.0.1";
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
          name = "vpn-only";
          description = "DHCP network restricted to the Mihomo vpn-only selector";
          devices.eth0 = {
            name = "eth0";
            type = "nic";
            nictype = "bridged";
            parent = vpnBridge;
          };
        }
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
  networking.tproxy.forward.${vpnBridge} = {
    port = 18300;
    tcp = [ "1-65535" ];
    udp = [ "1-65535" ];
    srcCIDRs = [ ];
  };

  # TProxy delivers proxied traffic through INPUT, never FORWARD. Drop all
  # ordinary forwarding, including bypass destinations and unsupported protocols.
  # No NAT on this bridge: there is no permitted direct Internet path.
  networking.nftables.tables.incus_vpn_only = {
    family = "inet";
    content = ''
      chain forward {
        type filter hook forward priority filter - 10; policy accept;
        iifname "${vpnBridge}" counter drop
      }
      chain input {
        type filter hook input priority filter - 10; policy accept;
        iifname "${vpnBridge}" meta mark ${toString config.networking.tproxy.mark} accept
        iifname "${vpnBridge}" udp sport 68 udp dport 67 accept
        iifname "${vpnBridge}" ct direction reply ct state established,related accept
        # Host-owned addresses bypass TProxy. Allow hosted websites directly;
        # the regular NixOS input firewall still controls which ports are open.
        iifname "${vpnBridge}" tcp dport { 80, 443 } counter accept
        # Prevent use of host DNS or explicit proxies to escape the selector.
        iifname "${vpnBridge}" counter drop
      }
    '';
  };

  networking = {
    bridges.${vpnBridge}.interfaces = [ ];
    interfaces.${vpnBridge}.ipv4.addresses = [
      {
        address = vpnGateway;
        prefixLength = 24;
      }
    ];
    firewall.interfaces.${vpnBridge}.allowedUDPPorts = [ 67 ];
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

  systemd.network.networks."40-${vpnBridge}" = {
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
