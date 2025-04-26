{
  inputs,
  config,
  ...
}: {
  imports = [
    inputs.self.nixosModules.profiles.bluetooth
    inputs.self.nixosModules.profiles.corectrl
    inputs.self.nixosModules.profiles.netman
    inputs.self.nixosModules.profiles.openrgb
    inputs.self.nixosModules.profiles.libvirt
    inputs.self.nixosModules.profiles.persist-yggdrasil
    inputs.self.nixosModules.profiles.pmbootstrap
    inputs.self.nixosModules.roles.desktop

    ./miner.nix

    ./hardware.nix
    ./mounts.nix
    ./ollama.nix
  ];

  # nixpkgs.localSystem = {
  #   gcc.arch = "x86-64-v2";
  #   gcc.tune = "znver3";
  #   system = "x86_64-linux";
  # };
  # nix.settings.system-features = [ "big-parallel" "gccarch-x86-64-v2" ];

  systemd.network.networks = {
    # "40-wgav" = {
    #   routes = [
    #     {
    #       Destination = "::/0";
    #       Type = "unreachable";
    #       Table = 700;
    #     }
    #   ];
    #   routingPolicyRules = [
    #     {
    #       FirewallMark = 700;
    #       Table = 700;
    #     }
    #     # {
    #     #   routingPolicyRuleConfig = {
    #     #     User = "alex";
    #     #     Table = 700;
    #     #   };
    #     # }
    #   ];
    # };
  };

  # age.secrets.wg-key-averyan.file = ../../secrets/wireguard/alligator.age;
  # networking.wireguard.interfaces = {
  #   wgav = {
  #     allowedIPsAsRoutes = false;
  #     privateKeyFile = config.age.secrets.wg-key-averyan.path;
  #     peers = [
  #       {
  #         publicKey = "h+76esMcmPLakUN/1vDlvGGf2Ovmw/IDKKxFtqXCdm8=";
  #         allowedIPs = ["0.0.0.0/0"];
  #         endpoint = "vpn.averyan.ru:51820";
  #         persistentKeepalive = 25;
  #       }
  #     ];
  #   };
  # };

  system.stateVersion = "24.05";

  persist.tmpfsSize = "10G";

  networking = {
    firewall.allowedTCPPorts = [25565];

    # interfaces.wgav = {
    #   ipv4 = {
    #     addresses = [
    #       {
    #         address = "10.8.7.250";
    #         prefixLength = 32;
    #       }
    #     ];
    #     routes = [
    #       {
    #         address = "10.8.7.0";
    #         prefixLength = 24;
    #       }
    #       {
    #         address = "10.8.7.0";
    #         prefixLength = 24;
    #         options.table = "700";
    #       }
    #       {
    #         address = "0.0.0.0";
    #         prefixLength = 0;
    #         via = "10.8.7.1";
    #         options.table = "700";
    #       }
    #     ];
    #   };
    # };

    # defaultGateway = {
    #   address = "192.168.3.1";
    #   interface = "enp10s0";
    # };

    # interfaces.enp10s0 = {
    #   ipv4 = {
    #     addresses = [{
    #       address = "192.168.3.60";
    #       prefixLength = 24;
    #     }];
    #   };
    # };
  };
}
