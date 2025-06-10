{
  boot.kernelParams = [
    "intel_iommu=on"
    "iommu=pt"
  ];

  virtualisation.libvirtd.enable = true;
  users.users.alex.extraGroups = ["libvirtd"];

  networking = {
    bridges.virbr0.interfaces = [];
    interfaces.virbr0 = {
      ipv4 = {
        addresses = [
          {
            address = "10.34.82.1";
            prefixLength = 24;
          }
        ];
      };
    };
    nat.internalInterfaces = ["virbr0"];
  };
  systemd.network.networks."40-virbr0" = {
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

  persist.state.dirs = ["/var/lib/libvirt"];
}
