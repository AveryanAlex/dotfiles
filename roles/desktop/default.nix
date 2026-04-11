{
  secrets,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ../core
    ../dev
    ./apps/wezterm.nix
    ./apps/alacritty.nix
    ./apps/firefox.nix
    ./apps/misc-a.nix
    ./apps/mpv.nix
    ./shell
    ./compat.nix
    ./deployapp.nix
    ./tuning.nix
    ./tank.nix
    ./distrobox.nix
    ../../profiles/embedded.nix
    ../../profiles/filemanager.nix
    ../../profiles/flatpak.nix
    ../../profiles/fonts.nix
    ../../profiles/kernel.nix
    ../../profiles/light.nix
    ../../profiles/mail.nix
    ../../profiles/music.nix
    ../../profiles/printing.nix
    ../../profiles/sdr.nix
    ../../profiles/sync.nix
    # ./waydroid.nix
    # ./opensnitch.nix
  ];

  # Enable transparent proxy for outbound traffic on desktops. Server and
  # family machines run mihomo as a plain listener without host interception
  # -- only desktops have tproxy.output.enable set, so mihomo only sees
  # intercepted traffic here.
  networking.tproxy.output.enable = true;

  # networking.firewall.allowedTCPPorts = [18298];

  # networking.proxy = rec {
  #   httpProxy = "socks5://127.0.0.1:10808";
  #   httpsProxy = httpProxy;
  # };

  # programs.appimage.enable = true;
  # environment.systemPackages = with pkgs; [ocl-icd];

  nixcfg.desktop = true;

  # hm.services.network-manager-applet.enable = true;
  # programs.adb.enable = true;

  programs.wireshark.enable = true;
  environment.systemPackages = [
    pkgs.wireshark
    # pkgs.openfortivpn
    pkgs.ocl-icd
    pkgs.android-tools
  ];
  # systemd.packages = [pkgs.fork.amneziawg-tools];

  programs.nh = {
    enable = true;
    flake = "/home/alex/projects/AveryanAlex/dotfiles";
  };

  boot = {
    kernelParams = [
      "zswap.enabled=1"
      "zswap.compressor=zstd"
      "zswap.max_pool_percent=30"
    ];

    # plymouth.enable = true;
    loader.timeout = 0;
  };

  programs.gnome-disks.enable = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  home-manager.users.alex = {
    home.stateVersion = lib.mkForce "26.05";

    dconf.settings = {
      "org/virt-manager/virt-manager".xmleditor-enabled = true;
      "org/virt-manager/virt-manager/connections".uris = [
        "qemu+ssh://alex@whale/system"
        "qemu:///system"
      ];
      "org/virt-manager/virt-manager/connections".autoconnect = [ "qemu:///system" ];
    };
    home.packages = [ pkgs.virt-manager ];
  };
}
