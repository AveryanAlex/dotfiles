{ pkgs, ... }:
let
  hostAddress = "95.165.105.90";
  machineAddress = "10.78.0.15";
  sshForwardPort = 17428;
  btrfsPoolPath = "/var/lib/incus-btrfs";

  direnvConfig = pkgs.writeTextDir "etc/direnv/direnvrc" ''
    source ${pkgs.nix-direnv}/share/nix-direnv/direnvrc

    if [[ -z ''${INCUS_NIX_ROOT:-} ]]; then
      export INCUS_NIX_ROOT="/nix/var/nix/gcroots/incus/$(hostname)"
    fi

    declare -A direnv_layout_dirs
    direnv_layout_dir() {
      local hash
      hash="$(printf %s "$PWD" | sha256sum | cut -d ' ' -f1)"
      echo "''${direnv_layout_dirs[$PWD]:=$INCUS_NIX_ROOT/direnv/$hash}"
    }
  '';

  nixTools = pkgs.buildEnv {
    name = "incus-nix-tools";
    paths = [
      pkgs.bash
      pkgs.coreutils
      pkgs.direnv
      pkgs.nix
      direnvConfig
    ];
    pathsToLink = [
      "/bin"
      "/etc/direnv"
    ];
  };

  hostNixShell = pkgs.writeText "host-nix.sh" ''
    export PATH="${nixTools}/bin:$PATH"
    export NIX_REMOTE=daemon
    export NIX_CONFIG="experimental-features = nix-command flakes"
    export NIX_SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    export DIRENV_CONFIG="${nixTools}/etc/direnv"

    if [ -z "''${INCUS_NIX_ROOT:-}" ]; then
      export INCUS_NIX_ROOT="/nix/var/nix/gcroots/incus/$(hostname)"
    fi

    case $- in
      *i*) eval "$(direnv hook bash)" ;;
    esac
  '';
in
{
  fileSystems.${btrfsPoolPath} = {
    device = "UUID=2c7a9cef-7b9a-4cfb-b8e1-9e47ef89b628";
    fsType = "btrfs";
    options = [
      "compress=zstd:3"
      "discard=async"
      "noatime"
      "subvol=@incus"
    ];
  };

  # @incus must be empty before this generation is deployed. Keep the shared
  # dir-backed default pool until every instance has been migrated and verified.
  virtualisation.incus.preseed.storage_pools = [
    {
      name = "btrfs";
      driver = "btrfs";
      # Incus 7.0 does not accept volume.btrfs.compression as a pool default;
      # the declarative mount above applies zstd:3 to newly written data.
      config.source = btrfsPoolPath;
    }
  ];

  virtualisation.incus.preseed.profiles = [
    {
      name = "host-nix";
      description = "Read-only whale Nix store with host daemon and nix-direnv";
      config = {
        "environment.DIRENV_CONFIG" = "${nixTools}/etc/direnv";
        "environment.NIX_CONFIG" = "experimental-features = nix-command flakes";
        "environment.NIX_REMOTE" = "daemon";
        "environment.NIX_SSL_CERT_FILE" = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        "environment.PATH" = "${nixTools}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin";
      };
      devices = {
        host-nix-shell = {
          type = "disk";
          source = "${hostNixShell}";
          path = "/etc/profile.d/host-nix.sh";
          readonly = "true";
        };
        nix-daemon = {
          type = "disk";
          source = "/nix/var/nix/daemon-socket";
          path = "/nix/var/nix/daemon-socket";
          readonly = "true";
        };
        nix-store = {
          type = "disk";
          source = "/nix/store";
          path = "/nix/store";
          readonly = "true";
        };
      };
    }
  ];

  systemd.services = {
    incus.unitConfig.RequiresMountsFor = [ btrfsPoolPath ];
    incus-preseed.unitConfig.RequiresMountsFor = [ btrfsPoolPath ];
    incus-startup.unitConfig.RequiresMountsFor = [ btrfsPoolPath ];
  };

  systemd.tmpfiles.rules = [
    "d /nix/var/nix/gcroots/incus/bobby 0755 root root -"
  ];

  systemd.network.networks."40-inoprbr0".dhcpServerStaticLeases = [
    {
      MACAddress = "10:66:6a:74:86:1d";
      Address = machineAddress;
    }
  ];

  systemd.network.networks."40-incusbr0".dhcpServerStaticLeases = [
    {
      MACAddress = "10:66:6a:0e:1d:78";
      Address = "10.77.0.45";
    }
  ];

  networking.nat.forwardPorts = [
    {
      sourcePort = sshForwardPort;
      proto = "tcp";
      destination = "${machineAddress}:22";
      loopbackIPs = [ hostAddress ];
    }
  ];

  networking.firewall.allowedTCPPorts = [ sshForwardPort ];
}
