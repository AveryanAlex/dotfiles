{
  config,
  pkgs,
  ...
}:
{
  # LEGACY SECTION
  virtualisation.podman = {
    enable = true;
    extraPackages = with pkgs; [
      slirp4netns
    ];
    defaultNetwork.settings.dns_enabled = true;
  };

  virtualisation.oci-containers.backend = "podman";
  # virtualisation.containers.containersConf.settings.network.network_backend = lib.mkForce "cni"; # nftables workaround

  # ROOTLESS SECTION
  users.users.alex = {
    subUidRanges = [
      {
        count = 1000000;
        startUid = 100000;
      }
    ];
    subGidRanges = [
      {
        count = 1000000;
        startGid = 100000;
      }
    ];
  };

  hm = {
    services.podman = {
      enable = true;
      # settings.storage.storage.driver = "btrfs";
    };

    systemd.user.sessionVariables = rec {
      # CONTAINER_HOST = "unix:///run/user/${builtins.toString config.users.users.alex.uid}/podman/podman.sock";
      # DOCKER_HOST = CONTAINER_HOST;
      REGISTRY_AUTH_FILE = config.age.secrets.podman-auth.path;
    };
  };

  # systemd.user.services.podman = {
  #   serviceConfig.UnsetEnvironment = [ "CONTAINER_HOST" ];
  # };

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  age.secrets.podman-auth = {
    file = ../secrets/creds/podman.age;
    mode = "600";
    owner = "alex";
    group = "users";
  };

  persist.state.homeDirs = [
    {
      directory = ".local/share/containers";
      mode = "u=rwx,g=,o=";
    }
  ];
  persist.state.dirs = [
    {
      directory = "/root/.local/share/containers";
      mode = "u=rwx,g=,o=";
    }
    {
      directory = "/var/lib/containers";
      mode = "u=rwx,g=rx,o=rx";
    }
  ];
}
