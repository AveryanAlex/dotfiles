{
  inputs,
  pkgs,
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
    ./gnome.nix
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

  networking.nftables.tables.xray-nat = {
    family = "inet";
    content =
      let
        rule = ''
          ip daddr { 0.0.0.0/8, 10.0.0.0/8, 127.0.0.0/8, 169.254.0.0/16, 172.16.0.0/12, 192.168.0.0/16, 224.0.0.0/4, 240.0.0.0/4 } return
          ip6 daddr { ::1/128, fc00::/7, fe80::/10, ff00::/8 } return
          tcp dport { 80, 443 } meta mark != 18298 redirect to :18298
          udp dport { 443 } meta mark != 18298 redirect to :18298
          # ip protocol tcp meta mark != 18298 redirect to :18298
          # ip protocol udp meta mark != 18298 redirect to :18298
        '';
      in
      ''
        chain out {
          type nat hook output priority mangle - 10; policy accept;
          ${rule}
        }

        chain pre {
          type nat hook prerouting priority dstnat - 10; policy accept;
        }
      '';
  };

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
    flake = "/home/alex/projects/averyanalex/dotfiles";
  };

  boot = {
    # plymouth.enable = true;
    loader.timeout = 0;
  };

  programs.gnome-disks.enable = true;

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  home-manager.users.alex = {
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
