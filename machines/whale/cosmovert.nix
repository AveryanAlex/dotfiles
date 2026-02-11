{ pkgs, ... }:
let
  dockerImage = pkgs.dockerTools.pullImage {
    imageName = "wordpress";
    finalImageTag = "latest";
    imageDigest = "sha256:d2d062bf3903cd7b73442a5266acff12f00ed66b48808f9b0d269e8d775b429f";
    sha256 = "u8P1PE8R4v6rncL8PvZktj2ExxD+TXIARg9JqIk6wY0=";
  };
in
{
  systemd.tmpfiles.rules = [
    "d /persist/cosmovert 755 33 33 - -"
  ];

  services.nginx.virtualHosts."cosmovert.ru" = {
    useACMEHost = "cosmovert.ru";
    locations."/".proxyPass = "http://127.0.0.1:8527";
    locations."/".proxyWebsockets = true;
  };

  # networking.firewall.interfaces."vms".allowedTCPPorts = [3306];

  # containers.cosmovert = {
  #   autoStart = true;
  #   ephemeral = true;

  #   privateNetwork = true;
  #   hostBridge = "vms";
  #   localAddress = "192.168.12.73/24";

  #   extraFlags = ["--system-call-filter=@keyring" "--system-call-filter=bpf"];

  #   bindMounts = {
  #     "/wp-data" = {
  #       hostPath = "/persist/cosmovert";
  #       isReadOnly = false;
  #     };
  #   };

  #   config = {
  #     config,
  #     pkgs,
  #     ...
  #   }: {
  #     system.stateVersion = "24.05";

  #     networking = {
  #       defaultGateway = {
  #         address = "192.168.12.1";
  #         interface = "eth0";
  #       };
  #       firewall.enable = false;
  #       useHostResolvConf = false;
  #       nameservers = ["9.9.9.9" "8.8.8.8" "1.1.1.1" "77.88.8.8"];
  #     };
  #     services.resolved.enable = true;

  virtualisation.oci-containers = {
    containers = {
      cosmovert-wp = {
        image = "wordpress";
        imageFile = dockerImage;
        volumes = [
          "/persist/cosmovert:/var/www/html"
        ];
        ports = [ "127.0.0.1:8527:80" ];
        extraOptions = [ "--network=slirp4netns" ];
        environment = {
          TZ = "Europe/Moscow";
          ENABLE_HTTPS = "true";
        };
      };
    };
    backend = "podman";
  };
  #   };
  # };
}
