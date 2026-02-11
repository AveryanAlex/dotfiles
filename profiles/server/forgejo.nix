{ config, ... }:
{
  services.forgejo = {
    enable = true;
    settings = {
      server = {
        ROOT_URL = "https://git.neutrino.su/";
        HTTP_PORT = 3826;
        DOMAIN = "git.neutrino.su";
        # SSH_PORT = 7422;
      };
      actions = {
        ENABLED = true;
      };
      service.DISABLE_REGISTRATION = true;
      session.COOKIE_SECURE = true;
    };
    lfs.enable = true;
    database = {
      type = "postgres";
      createDatabase = true;
    };
  };

  users = {
    users.forgejo.uid = 836;
    groups.forgejo.gid = 836;
  };

  persist.state.dirs = [
    {
      directory = "/var/lib/forgejo";
      user = "forgejo";
      group = "forgejo";
      mode = "u=rwx,g=rx,o=";
    }
  ];
  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [
    3826
    7422
  ];

  systemd.services.forgejo = {
    requires = [ "postgresql.service" ];
    after = [ "postgresql.service" ];
  };

  # services.woodpecker-server = {
  #   enable = true;
  #   environment = {
  #     WOODPECKER_HOST = "https://wp.neutrino.su";
  #     WOODPECKER_OPEN = true;
  #   };
  # };

  #   # Runner
  #   systemd.tmpfiles.rules = [
  #     # "d /persist/ptero/podman 700 0 0 - -"
  #     "d /persist/forgejo-runner/docker 710 0 0 - -"
  #     # "d /persist/ptero/wings 700 988 988 - -"
  #     # "d /persist/ptero/wings-configs 700 988 988 - -"
  #   ];
  #
  #   age.secrets.forgejo-runner-token.file = ../../secrets/creds/forgejo-runner-token.age;
  #
  #   containers.forgejo-runner = {
  #     autoStart = true;
  #     ephemeral = true;
  #
  #     privateNetwork = true;
  #     hostBridge = "vms";
  #     localAddress = "192.168.12.72/24";
  #
  #     extraFlags = ["--system-call-filter=@keyring" "--system-call-filter=bpf"];
  #
  #     bindMounts = {
  #       # "/var/lib/pterodactyl/" = {
  #       #   hostPath = "/persist/ptero/wings";
  #       #   isReadOnly = false;
  #       # };
  #       "/run/forgejo-token" = {
  #         hostPath = config.age.secrets.forgejo-runner-token.path;
  #         isReadOnly = true;
  #       };
  #       "/var/lib/docker/" = {
  #         hostPath = "/persist/forgejo-runner/docker";
  #         isReadOnly = false;
  #       };
  #     };
  #
  #     config = {pkgs, ...}: {
  #       system.stateVersion = "23.05";
  #
  #       networking = {
  #         defaultGateway = {
  #           address = "192.168.12.1";
  #           interface = "eth0";
  #         };
  #         firewall.enable = false;
  #         useHostResolvConf = false;
  #         nameservers = ["9.9.9.9" "8.8.8.8" "1.1.1.1" "77.88.8.8"];
  #       };
  #       services.resolved.enable = true;
  #
  #       virtualisation.docker = {
  #         enable = true;
  #         autoPrune = {
  #           enable = true;
  #         };
  #       };
  #
  #       services.gitea-actions-runner = {
  #         package = pkgs.forgejo-actions-runner;
  #         instances.neutrino = {
  #           enable = true;
  #           url = "https://git.neutrino.su";
  #           tokenFile = "/run/forgejo-token";
  #           name = "whale";
  #           labels = ["ubuntu-latest:docker://node:16-bullseye"];
  #           settings = {
  #             capacity = 4;
  #           };
  #         };
  #       };
  #     };
  #   };
}
