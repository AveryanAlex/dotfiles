{
  nix = {
    settings = {
      experimental-features = [
        "auto-allocate-uids"
        "cgroups"
        "flakes"
        "nix-command"
      ];

      # use temp uid for builds instead of nixbld* users
      auto-allocate-uids = true;
      # same files hardlinking for /nix/store
      auto-optimise-store = true;
      # remote builders use binary cache
      builders-use-substitutes = true;
      # set finite timeout for binary cache
      connect-timeout = 5;
      # don't stop building if one of builds fails
      keep-going = true;
      # longer logs, default - 10
      log-lines = 25;
      # prevent out of disk space
      max-free = 4096 * 1024 * 1024;
      min-free = 512 * 1024 * 1024;
      # show full trace on eval errors
      show-trace = true;
      # add @wheel to trusted users
      trusted-users = [
        "root"
        "@wheel"
      ];
      # build in cgroups
      use-cgroups = true;
      # cleanup $HOME
      use-xdg-base-directories = true;

      # additional binary caches
      substituters = [
        "https://mirror.yandex.ru/nixos"
        "https://nix-community.cachix.org"
        "https://nixpkgs-unfree.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      ];
    };

    # disable channels (we use flakes)
    channel.enable = false;

    # low priority
    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "idle";
    daemonIOSchedPriority = 7;
  };

  environment.sessionVariables.NIX_REMOTE = "daemon";

  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = 250;

  systemd.services.nix-daemon = {
    environment.TMPDIR = "/nix/tmp";
  };
  systemd.tmpfiles.rules = [ "d /nix/tmp 0755 root root 1d" ];
}
