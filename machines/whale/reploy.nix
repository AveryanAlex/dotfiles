{
  config,
  inputs,
  lib,
  secrets,
  ...
}:
{
  imports = [ inputs.reploy.nixosModules.default ];

  age.secrets.reploy-jwt = {
    file = "${secrets}/creds/reploy-whale.age";
    mode = "0400";
  };

  # Reploy replaces Podman's scheduled updater on whale only.
  virtualisation.quadlet.autoUpdate.enable = lib.mkForce false;
  systemd.services.podman-auto-update.enable = false;
  systemd.timers.podman-auto-update.enable = false;

  services.reploy = {
    enable = true;
    backend = "podman";
    enableHttp = true;
    enableSocket = true;
    httpAddr = "127.0.0.1:9080";
    socketPath = "/run/reploy.sock";
    jwtSecretFile = config.age.secrets.reploy-jwt.path;

    extraEnvironment = {
      REGISTRY_AUTH_FILE = config.age.secrets.podman-auth.path;
      RUST_LOG = "reploy=info";
    };

    trigger = {
      enable = true;
      images = [ "*" ];
      dates = "*-*-* 04:00:00";
      randomizedDelaySec = "15m";
      persistent = true;
    };
  };

  services.nginx.virtualHosts."whale.averyan.ru" = {
    useACMEHost = "averyan.ru";
    locations."/reploy/".proxyPass = "http://127.0.0.1:9080/";
  };
}
