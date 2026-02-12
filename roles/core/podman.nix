{
  lib,
  config,
  inputs,
  secrets,
  ...
}:
{
  imports = [
    inputs.quadlet-nix.nixosModules.quadlet
  ];

  # enable podman and use it as oci-containers backend
  virtualisation.podman.enable = true;
  virtualisation.oci-containers.backend = "podman"; # already default

  # daily images cleanup for system podman
  virtualisation.podman.autoPrune = {
    enable = true;
    dates = "daily";
    # flags = [ "--all" ];
  };

  # enable docker socket for docker compatibility
  # virtualisation.podman.dockerSocket.enable = true;
  # TODO: monitoring

  # remove once is will be default value
  virtualisation.quadlet.autoEscape = true;

  # pme-* external, pmi-* internal

  # subnets for podman networks
  virtualisation.podman.defaultNetwork.settings = {
    dns_enabled = true;
    network_interface = "pme-default";
    # default network
    subnets = [
      {
        subnet = "10.88.0.0/16";
        gateway = "10.88.0.1";
      }
    ];
  };
  virtualisation.containers.containersConf.settings.network.default_subnet_pools = [
    # auto-assigned subnet
    {
      base = "10.89.0.0/16";
      size = 24;
    }
  ];
  # peek /24 from 10.90.0.0/16 for user-defined networks

  # nftables firewall
  virtualisation.containers.containersConf.settings.network.firewall_driver = lib.mkForce "none";
  networking.nat.internalInterfaces = [ "pme-*" ];
  networking.firewall.extraInputRules = ''iifname { "pme-*", "pmi-*" } udp dport 53 accept'';

  # use btrfs for storage if root is btrfs, otherwise use overlayfs
  virtualisation.containers.storage.settings.storage.driver =
    if config.fileSystems."/".fsType == "btrfs" then "btrfs" else "overlay";

  # registry auth file for root user and podman group
  age.secrets.podman-auth = {
    file = "${secrets}/creds/podman.age";
    mode = "440";
    owner = "root";
    group = "podman";
  };
  environment.sessionVariables.REGISTRY_AUTH_FILE = config.age.secrets.podman-auth.path;
  users.users.alex.extraGroups = [ "podman" ];

  # allow to bind <1024 ports without root
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  # LEGACY
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

  # assertions = [
  #   {
  #     assertion = !config.networking.nftables.flushRuleset;
  #     message = "podman requires nftables.flushRuleset to be disabled";
  #   }
  # ];
}
