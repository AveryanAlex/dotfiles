{ pkgs, ... }:
{
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
    daemon.settings.dns = [
      "8.8.8.8"
      "1.1.1.1"
    ];
  };
  # hm.home.sessionVariables.DOCKER_HOST = "unix:///run/user/1000/podman/podman.sock";
  # hm.home.packages = [ pkgs.docker-client ];
}
