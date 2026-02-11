{ pkgs, ... }:
{
  virtualisation.oci-containers = {
    containers = {
      ai-box = {
        image = "ghcr.io/averyanalex/ai-box";
        imageFile = pkgs.dockerTools.pullImage {
          imageName = "ghcr.io/averyanalex/ai-box";
          finalImageTag = "latest";
          imageDigest = "sha256:e65ab2ae8d3ad198a1d376183b86da3765d771de39faec06e37758c6de0ec8ac";
          sha256 = "zTAwGwy5P25f62hBnvw/RmEtroe2VainKqJ9DncTk38=";
        };
        extraOptions = [ "--network=host" ];
      };
    };
  };
}
