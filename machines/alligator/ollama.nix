let
  name = "ollama";
  port = 11434;
in
{
  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ port ];

  systemd.tmpfiles.rules = [
    "d /var/lib/${name} 700 100999 100999 - -"
  ];

  virtualisation.quadlet = {
    containers.${name} = {
      containerConfig = {
        image = "docker.io/ollama/ollama:rocm";
        autoUpdate = "registry";
        networks = [ "host" ];
        devices = [
          "/dev/kfd"
          "/dev/dri"
        ];
        volumes = [ "/var/lib/${name}:/root/.ollama" ];
        gidMaps = [ "0:100000:100000" ];
        uidMaps = [ "0:100000:100000" ];
      };
      serviceConfig = {
        MemoryMax = "24G";
      };
    };
  };
}
