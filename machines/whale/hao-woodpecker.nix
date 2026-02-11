{
  systemd.tmpfiles.rules = [
    "d /persist/hao-woodpecker/docker 700 0 0 - -"
    "d /persist/hao-woodpecker/data 700 0 0 - -"
  ];

  networking = {
    bridges.haowpbr.interfaces = [ ];
    nat.internalInterfaces = [ "haowpbr" ];
    interfaces.haowpbr = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.31.1";
            prefixLength = 24;
          }
        ];
      };
    };
  };
  systemd.network.networks."40-haowpbr" = {
    networkConfig = {
      IPv6AcceptRA = false;
      ConfigureWithoutCarrier = true;
    };
  };

  containers.haowp = {
    autoStart = true;
    ephemeral = true;

    privateNetwork = true;
    hostBridge = "haowpbr";
    localAddress = "192.168.31.2/24";

    extraFlags = [
      "--system-call-filter=@keyring"
      "--system-call-filter=bpf"
    ];

    bindMounts = {
      "/var/lib/docker/" = {
        hostPath = "/persist/hao-woodpecker/docker";
        isReadOnly = false;
      };
      "/root/" = {
        hostPath = "/persist/hao-woodpecker/data";
        isReadOnly = false;
      };
    };

    config =
      { pkgs, ... }:
      {
        system.stateVersion = "25.05";

        environment.systemPackages = with pkgs; [
          micro
          curl
          wget
        ];

        networking = {
          defaultGateway = {
            address = "192.168.31.1";
            interface = "eth0";
          };
          firewall.enable = true;
          useHostResolvConf = false;
          nameservers = [
            "9.9.9.9"
            "8.8.8.8"
            "1.1.1.1"
            "77.88.8.8"
          ];
        };
        services.resolved.enable = true;

        virtualisation.docker = {
          enable = true;
          autoPrune = {
            enable = true;
          };
        };
      };
  };
}
