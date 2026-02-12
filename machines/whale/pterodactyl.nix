{
  config,
  pkgs,
  secrets,
  ...
}:
let
  panelDockerImage = pkgs.dockerTools.pullImage {
    imageName = "ghcr.io/pterodactyl/panel";
    finalImageTag = "latest";
    imageDigest = "sha256:bc685c5002b88e518d9382fb0a57af7b753a498bfc9099a70dff70724c154a06";
    sha256 = "sha256-myQR452MQbrOQ3gjn7qesQSnZl5OQSL6TBpkgdqm3Qw=";
  };

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
    "d /persist/ptero/panel 700 0 0 - -"
    "d /persist/ptero/mysql 700 84 84 - -"
    "d /persist/ptero/wings 700 988 988 - -"
    "d /persist/ptero/wings-configs 700 988 988 - -"
  ];

  networking.nat.forwardPorts =
    let
      common = {
        destination = "192.168.12.50:25000-25010";
        sourcePort = "25000:25010";
        loopbackIPs = [ "95.165.105.90" ];
      };
    in
    [
      (common // { proto = "tcp"; })
      (common // { proto = "udp"; })
    ];

  age.secrets.pterodactyl-panel-passwords.file = "${secrets}/intpass/pterodactyl-panel.age";
  age.secrets.pterodactyl-redis-password.file = "${secrets}/intpass/pterodactyl-redis.age";

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
      "/var/lib/mysql/" = {
        hostPath = "/persist/ptero/mysql";
        isReadOnly = false;
      };
      "/srv/pterodactyl/" = {
        hostPath = "/persist/ptero/panel";
        isReadOnly = false;
      };
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
      "/run/panel.env".hostPath = config.age.secrets.pterodactyl-panel-passwords.path;
      "/run/redis-pass".hostPath = config.age.secrets.pterodactyl-redis-password.path;
    };

    config =
      { pkgs, ... }:
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
            panel = {
              image = "ghcr.io/pterodactyl/panel";
              imageFile = panelDockerImage;
              volumes = [
                "/srv/pterodactyl/var/:/app/var/"
                "/srv/pterodactyl/logs/:/app/storage/logs"
              ];
              extraOptions = [ "--network=host" ];
              environment = {
                APP_URL = "https://ptero.averyan.ru";
                APP_TIMEZONE = "Europe/Moscow";
                APP_SERVICE_AUTHOR = "alex@averyan.ru";
                APP_ENV = "production";
                APP_ENVIRONMENT_ONLY = "false";

                CACHE_DRIVER = "redis";
                SESSION_DRIVER = "redis";
                QUEUE_DRIVER = "redis";
                REDIS_HOST = "127.0.0.1";
                REDIS_PORT = "6379";

                DB_HOST = "127.0.0.1";
                DB_PORT = "3306";
                DB_DATABASE = "panel";
                DB_USERNAME = "panel";
              };
              environmentFiles = [ "/run/panel.env" ];
            };
            wings = {
              # image = "ghcr.io/averyanalex/wings:v1.11.0-np";
              image = "ghcr.io/pterodactyl/wings";
              imageFile = wingsDockerImage;
              volumes = [
                "/var/run/docker.sock:/var/run/docker.sock"
                "/var/lib/docker/containers/:/var/lib/docker/containers/"
                "/etc/pterodactyl/:/etc/pterodactyl/"
                "/var/lib/pterodactyl/:/var/lib/pterodactyl/"
                "/tmp/pterodactyl/:/tmp/pterodactyl/"
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

        systemd.tmpfiles.rules = [
          "d /tmp/pterodactyl/ 700 988 988 - -"
        ];

        virtualisation.docker = {
          enable = true;
          autoPrune = {
            enable = true;
          };
        };

        services.redis.servers.panel = {
          enable = true;
          port = 6379;
          requirePassFile = "/run/redis-pass";
        };

        services.mysql = {
          enable = true;
          package = pkgs.mariadb;
          settings = {
            mysqld = {
              max_connections = 512;
            };
          };
          ensureDatabases = [ "panel" ];
          ensureUsers = [
            {
              name = "panel";
              ensurePermissions = {
                "panel.*" = "ALL PRIVILEGES";
              };
            }
          ];
        };
      };
  };
}
