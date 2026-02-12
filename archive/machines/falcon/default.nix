{ inputs, ... }:
{
  imports = [
    inputs.self.nixosModules.hardware.aeza
    inputs.self.nixosModules.roles.minimal

    inputs.self.nixosModules.profiles.remote-builder-client
    # inputs.self.nixosModules.profiles.server.aplusmuz

    ./mounts.nix
    ./tor.nix
    ./proxy.nix
    ./xray.nix
    ./wg.nix
  ];

  system.stateVersion = "23.05";

  age.secrets.wg-key.file = ../../secrets/wireguard/hawk.age;

  boot.kernel.sysctl = {
    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;

    "net.ipv6.conf.all.forwarding" = false;
    "net.ipv6.conf.default.forwarding" = false;
  };

  networking = {
    interfaces = {
      ens3 = {
        ipv4 = {
          addresses = [
            {
              address = "150.241.67.193";
              prefixLength = 32;
            }
          ];
          routes = [
            {
              address = "10.0.0.1";
              prefixLength = 32;
            }
            {
              address = "0.0.0.0";
              prefixLength = 0;
              via = "10.0.0.1";
            }
          ];
        };
      };
    };

    nat.externalInterface = "ens3";
    nat.internalInterfaces = [ "wgvpn" ];

    firewall.allowedUDPPorts = [ 51820 ];
  };
}
