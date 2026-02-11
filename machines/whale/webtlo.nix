{
  config,
  ...
}:
{
  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        webtlo = {
          containerConfig = {
            image = "docker.io/berkut174/webtlo:latest";
            autoUpdate = "registry";
            volumes = [ "/var/lib/webtlo:/data" ];
            networks = [ networks.webtlo.ref ];
            ip = "10.90.26.2";
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
        };
      };
      networks = {
        webtlo.networkConfig = {
          subnets = [ "10.90.26.0/24" ];
          podmanArgs = [ "--interface-name=pme-webtlo" ];
        };
      };
    };

  networking.firewall.interfaces.pme-webtlo.allowedTCPPorts = [
    8173 # qbittorrent
    8080 # http proxy
  ];

  # access with ssh -L 1844:10.90.26.2:80 whale

  persist.state.dirs = [
    {
      directory = "/var/lib/webtlo";
      user = "101000";
      group = "101000";
      mode = "u=rwx,g=,o=";
    }
  ];
}
