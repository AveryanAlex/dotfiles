let
  name = "mtproto";
in
{ config, ... }:
{
  age.secrets.${name}.file = ./secret.age;

  # MTProto proxy uses raw TCP protocol
  # Nginx stream module proxies port 443 to the container

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      networks.${name}.networkConfig = {
        subnets = [ "10.90.94.0/24" ];
        podmanArgs = [ "--interface-name=pme-${name}" ];
      };

      containers.${name} = {
        containerConfig = {
          image = "docker.io/alexdoesh/mtproxy:latest";
          autoUpdate = "registry";
          networks = [ networks.${name}.ref ];
          ip = "10.90.94.2";
          environmentFiles = [ config.age.secrets.${name}.path ];
          gidMaps = [ "0:100000:100000" ];
          uidMaps = [ "0:100000:100000" ];
        };
        serviceConfig = {
          MemoryMax = "256M";
        };
      };
    };
}
