{ pkgs, ... }:
let
  wingsDockerImage = pkgs.dockerTools.pullImage {
    imageName = "ghcr.io/pterodactyl/wings";
    finalImageTag = "latest";
    imageDigest = "sha256:a56f3911b48c9ab96ad51b10d236c3caa318eae96d63c19d869c559b0f819582";
    sha256 = "YCcp4FLnY8KSwAbidS09R8QNKY4rChVx+6d6Tyj2nOE=";
  };
in
{
  systemd.tmpfiles.rules = [
    "d /persist/ptero/podman 700 0 0 - -"
    "d /persist/ptero/docker 710 0 0 - -"
    "d /persist/ptero/wings 700 988 988 - -"
    "d /persist/ptero/wings-configs 700 988 988 - -"
  ];

  containers.pterodactyl = {
    autoStart = true;
    ephemeral = true;

    privateNetwork = true;
    hostBridge = "vms";
    localAddress = "192.168.12.50/24";

    extraFlags = [
      "--system-call-filter=@keyring"
      "--system-call-filter=bpf"
    ];

    bindMounts = {
      "/var/lib/pterodactyl/" = {
        hostPath = "/persist/ptero/wings";
        isReadOnly = false;
      };
      "/etc/pterodactyl/" = {
        hostPath = "/persist/ptero/wings-configs";
        isReadOnly = false;
      };
      "/var/lib/docker/" = {
        hostPath = "/persist/ptero/docker";
        isReadOnly = false;
      };
      "/root/.local/share/containers/" = {
        hostPath = "/persist/ptero/podman";
        isReadOnly = false;
      };
    };

    config =
      {
        config,
        pkgs,
        ...
      }:
      {
        system.stateVersion = "23.05";

        networking = {
          defaultGateway = {
            address = "192.168.12.1";
            interface = "eth0";
          };
          firewall.enable = false;
          useHostResolvConf = false;
          nameservers = [
            "9.9.9.9"
            "8.8.8.8"
            "1.1.1.1"
            "77.88.8.8"
          ];
        };
        services.resolved.enable = true;

        virtualisation.podman = {
          enable = true;
        };

        virtualisation.oci-containers = {
          containers = {
            wings = {
              # image = "ghcr.io/averyanalex/wings:v1.11.0-np";
              image = "ghcr.io/pterodactyl/wings";
              imageFile = wingsDockerImage;
              volumes = [
                "/var/run/docker.sock:/var/run/docker.sock"
                "/var/lib/docker/containers/:/var/lib/docker/containers/"
                "/etc/pterodactyl/:/etc/pterodactyl/"
                "/var/lib/pterodactyl/:/var/lib/pterodactyl/"
              ];
              extraOptions = [ "--network=host" ];
              environment = {
                TZ = "Europe/Moscow";
                WINGS_UID = "988";
                WINGS_GID = "988";
                WINGS_USERNAME = "pterodactyl";
              };
            };
          };
        };

        virtualisation.docker = {
          enable = true;
          autoPrune = {
            enable = true;
          };
        };
      };
  };
}
