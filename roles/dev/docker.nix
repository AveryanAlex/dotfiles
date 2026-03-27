{ config, ... }:
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

  # use podman's registry auth for docker, avoid ~/.docker/config.json
  systemd.tmpfiles.rules = [
    "d /home/alex/.config/docker 0755 alex users -"
    "L+ /home/alex/.config/docker/config.json - - - - ${config.age.secrets.podman-auth.path}"
  ];
  hm.home.sessionVariables.DOCKER_CONFIG = "/home/alex/.config/docker";
}
