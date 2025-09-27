{
  config,
  ...
}:
{
  persist.state.dirs = [
    "/var/lib/ollama"
    "/var/lib/open-webui"
  ];

  virtualisation.quadlet =
    let
      inherit (config.virtualisation.quadlet) networks;
    in
    {
      containers = {
        open-webui = {
          containerConfig = {
            image = "ghcr.io/open-webui/open-webui:main";
            autoUpdate = "registry";
            volumes = [ "/var/lib/open-webui:/app/backend/data" ];
            networks = [ networks.ollama.ref ];
            ip = "10.100.18.2";
          };
        };
      };
      networks = {
        ollama.networkConfig = {
          subnets = [ "10.100.18.0/24" ];
          podmanArgs = [ "--interface-name=pme-ollama" ];
        };
      };
    };

  # virtualisation.oci-containers = {
  #   containers = {
  #     ollama = {
  #       image = "docker.io/ollama/ollama:rocm";
  #       # imageFile = ollamaImage;
  #       volumes = [
  #         "/var/lib/ollama:/root/.ollama"
  #       ];
  #       devices = [
  #         "/dev/kfd"
  #         "/dev/dri"
  #       ];
  #       # ports = [ "0.0.0.0:11434:11434" ];
  #       # extraOptions = [ "--network=slirp4netns" ];
  #     };
  #   };
  # };
}
