{ config, ... }:
let
  name = "newsrelay";
in
{
  systemd.tmpfiles.rules = [
    "d /persist/${name}/data 700 100999 100999 - -"
  ];

  age.secrets."${name}-bot" = {
    file = ./bot.age;
  };

  xrayNat.interfaces = [ "pme-${name}" ];

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        ${name} = {
          containerConfig = {
            image = "ghcr.io/averyanalex/newsrelay:latest";
            # autoUpdate = "registry";
            networks = [ networks.${name}.ref ];
            ip = "10.90.89.2";
            environments = {
              TZ = "Europe/Moscow";
              https_proxy = "http://10.90.89.1:8080";
            };
            volumes = [ "/persist/${name}/data:/data" ];
            environmentFiles = [ config.age.secrets."${name}-bot".path ];
            gidMaps = [ "0:100000:100000" ];
            uidMaps = [ "0:100000:100000" ];
          };
        };
      };

      networks = {
        ${name}.networkConfig = {
          subnets = [ "10.90.89.0/24" ];
          podmanArgs = [ "--interface-name=pme-${name}" ];
        };
      };
    };

  networking.firewall.interfaces."pme-${name}".allowedTCPPorts = [ 8080 ];
}
