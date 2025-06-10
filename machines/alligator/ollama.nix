{pkgs, ...}: let
#   ollamaImage = pkgs.dockerTools.pullImage {
#     imageName = "ollama/ollama";
#     finalImageTag = "0.6.7-rc0-rocm";
#     imageDigest = "sha256:98bee0d601a51d5b9791f41914db252188f1a715d67932ef686fcf8ae3361ee5";
#     sha256 = "sha256-zDFkGFEGgVumWLDkiSv02eHxBxpN6A3YwsOOVL3yY5w=";
#   };
# 
#   webuiImage = pkgs.dockerTools.pullImage {
#     imageName = "ghcr.io/open-webui/open-webui";
#     finalImageTag = "main";
#     imageDigest = "sha256:e8a0f40a2724e1b4c1573596e23cd1c6dce52e16a285e4fd9c713e3c5eec3eb0";
#     sha256 = "sha256-mvPa8usTIbUgX2vmzWCa5aCc7WHqthKesqnEzyUETnI=";
#   };
in {
  persist.state.dirs = ["/var/lib/ollama" "/var/lib/open-webui"];

  virtualisation.oci-containers = {
    containers = {
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:main";
        # imageFile = webuiImage;
        volumes = [
          "/var/lib/open-webui:/app/backend/data"
        ];
        ports = ["0.0.0.0:3012:8080"];
        extraOptions = ["--add-host=host.docker.internal:host-gateway" "--network=slirp4netns"];
      };

      ollama = {
        image = "docker.io/ollama/ollama:rocm";
        # imageFile = ollamaImage;
        volumes = [
          "/var/lib/ollama:/root/.ollama"
        ];
        devices = [
          "/dev/kfd"
          "/dev/dri"
        ];
        ports = ["0.0.0.0:11434:11434"];
        extraOptions = ["--network=slirp4netns"];
      };
    };
  };
}
