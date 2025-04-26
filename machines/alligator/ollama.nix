{pkgs, ...}: let
  ollamaImage = pkgs.dockerTools.pullImage {
    imageName = "ollama/ollama";
    finalImageTag = "rocm";
    imageDigest = "sha256:2092b61563b18fb73ae01224a28eb00d9f253248002b79eac96d237dee995c46";
    sha256 = "sha256-aCWpvH0AiCFZh/DN+SC90j4AJjaDIB30g8edKe+a5EU=";
  };

  webuiImage = pkgs.dockerTools.pullImage {
    imageName = "ghcr.io/open-webui/open-webui";
    finalImageTag = "main";
    imageDigest = "sha256:e8a0f40a2724e1b4c1573596e23cd1c6dce52e16a285e4fd9c713e3c5eec3eb0";
    sha256 = "sha256-mvPa8usTIbUgX2vmzWCa5aCc7WHqthKesqnEzyUETnI=";
  };
in {
  persist.state.dirs = ["/var/lib/ollama" "/var/lib/open-webui"];

  virtualisation.oci-containers = {
    containers = {
      open-webui = {
        image = "ghcr.io/open-webui/open-webui:main";
        imageFile = webuiImage;
        volumes = [
          "/var/lib/open-webui:/app/backend/data"
        ];
        ports = ["0.0.0.0:3012:8080"];
        extraOptions = ["--add-host=host.docker.internal:host-gateway" "--network=slirp4netns"];
      };

      ollama = {
        image = "ollama/ollama:rocm";
        imageFile = ollamaImage;
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
