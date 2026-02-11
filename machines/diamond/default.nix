{ inputs, ... }:
let
  wan = "enp2s0";
in
{
  imports = [
    inputs.self.nixosModules.roles.server

    inputs.self.nixosModules.profiles.networkd

    inputs.self.nixosModules.profiles.server.mysql

    ./hardware.nix
    ./mounts.nix

    ./pterodactyl.nix
  ];

  system.stateVersion = "22.05";

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv4.conf.default.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv6.conf.default.forwarding" = true;
  };

  systemd.network.networks = {
    "40-${wan}" = {
      gateway = [ "192.168.1.1" ];
      name = "${wan}";
      routes = [
        {
          routeConfig = {
            Destination = "192.168.1.1";
            Source = "192.168.1.7";
          };
        }
      ];
      networkConfig = {
        IPv6AcceptRA = false;
      };
    };

    "40-vms" = {
      networkConfig = {
        IPv6AcceptRA = false;
        ConfigureWithoutCarrier = true;
        DHCPServer = true;
      };
      dhcpServerConfig = {
        PoolOffset = 100;
        PoolSize = 50;
        EmitDNS = true;
        DNS = "9.9.9.9";
      };
    };
  };

  networking = {
    nft-firewall = {
      extraFilterForwardRules = [
        ''iifname { "vms" } oifname "${wan}" counter accept comment "allow LAN to WAN"''
        ''iifname "${wan}" oifname { "vms" } ct state { established, related } counter accept comment "allow established back to LAN"''
      ];
      extraNatPreroutingRules = [
        "ip daddr 10.57.1.50 tcp dport { 443, 2022 } dnat to 192.168.12.50"
        "ip daddr 192.168.1.7 tcp dport 25565-25575 dnat to 192.168.12.50"
      ];
      extraNatPostroutingRules = [ ''oifname "${wan}" masquerade'' ];
    };

    firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 443 ];
    firewall.interfaces."vms".allowedTCPPorts = [ 3306 ];

    bridges = {
      vms.interfaces = [ ];
    };

    interfaces = {
      vms = {
        ipv4 = {
          addresses = [
            {
              address = "192.168.12.1";
              prefixLength = 24;
            }
          ];
        };
      };
      ${wan} = {
        ipv4 = {
          addresses = [
            {
              address = "192.168.1.7";
              prefixLength = 24;
            }
          ];
        };
      };
    };
  };
}
