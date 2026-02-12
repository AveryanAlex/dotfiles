{
  systemd.tmpfiles.rules = [
    "d /persist/docker/docker 700 0 0 - -"
    "d /persist/docker/data 700 0 0 - -"
  ];

  networking.tproxy.forward.interfaces = [ "dockerbr" ];

  networking = {
    bridges.dockerbr.interfaces = [ ];
    nat.internalInterfaces = [ "dockerbr" ];
    interfaces.dockerbr = {
      ipv4 = {
        addresses = [
          {
            address = "192.168.30.1";
            prefixLength = 24;
          }
        ];
      };
    };
  };
  systemd.network.networks."40-dockerbr" = {
    networkConfig = {
      IPv6AcceptRA = false;
      ConfigureWithoutCarrier = true;
    };
  };

  services.nginx.virtualHosts = {
    "immich.averyan.ru" = {
      useACMEHost = "averyan.ru";
      locations."/".proxyPass = "http://192.168.30.2:2283";
      locations."/".proxyWebsockets = true;
    };
    "llm.averyan.ru" = {
      useACMEHost = "averyan.ru";
      locations."/".proxyPass = "http://192.168.30.2:3012";
      locations."/".proxyWebsockets = true;
    };
  };

  containers.docker = {
    autoStart = true;
    ephemeral = true;

    privateNetwork = true;
    hostBridge = "dockerbr";
    localAddress = "192.168.30.2/24";

    extraFlags = [
      "--system-call-filter=@keyring"
      "--system-call-filter=bpf"
    ];

    bindMounts = {
      "/var/lib/docker/" = {
        hostPath = "/persist/docker/docker";
        isReadOnly = false;
      };
      "/root/" = {
        hostPath = "/persist/docker/data";
        isReadOnly = false;
      };
      "/hometank/" = {
        hostPath = "/home/alex/tank";
        isReadOnly = false;
      };
    };

    config =
      { pkgs, ... }:
      {
        system.stateVersion = "24.11";

        environment.systemPackages = with pkgs; [
          micro
          curl
          wget
        ];

        networking = {
          defaultGateway = {
            address = "192.168.30.1";
            interface = "eth0";
          };
          firewall.enable = true;
          firewall.allowedTCPPorts = [ 2283 ];
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
