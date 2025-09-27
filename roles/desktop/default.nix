{
  inputs,
  pkgs,
  ...
}: {
  imports =
    [
      ../full.nix
      ../../dev
      ../../profiles/apps/wezterm.nix
      ./gnome.nix
      ./compat.nix
      ./deployapp.nix
      ./tuning.nix
    ]
    ++ (with inputs.self.nixosModules.profiles;
      with apps;
        [
          alacritty
          firefox
          misc-a
          mpv
        ]
        ++ (with games; [
          # minecraft
          # xonotic
        ])
        ++ (with gui; [
          # nix-colors
          # stylix
          # sway
          # clipboard
          # eww
          # portals
          # rofi
          # sway
          # hyprland
          # hyprlock
          # swaync
          # swayosd
          # swww
          # waybar
          # wm
        ])
        ++ [
          # jupyter
          # autologin
          embedded
          filemanager
          flatpak
          fonts
          kernel
          light
          mail
          music
          podman
          printing
          sdr
          sync
          tank
          # waydroid
          opensnitch
          xray
        ]);

  # networking.nftables.tables.xray-nat = {
  #   family = "inet";
  #   content = let
  #     skip = ''
  #       ip daddr { 127.0.0.0/8, 224.0.0.0/4, 192.168.0.0/16, 255.255.255.255 } return
  #       ip6 daddr { ::1, fe80::/10, fd00::/8 } return
  #     '';
  #   in ''
  #     chain pre {
  #       type nat hook prerouting priority dstnat; policy accept;
  #       ${skip}
  #       meta l4proto { tcp, udp } meta mark != 18298 redirect to :18298
  #     }

  #     chain out {
  #       type nat hook output priority mangle - 10; policy accept;
  #       ${skip}
  #       meta l4proto { tcp, udp } meta mark != 18298 redirect to :18298
  #     }
  #   '';
  # };

  # networking.proxy = rec {
  #   httpProxy = "socks5://127.0.0.1:10808";
  #   httpsProxy = httpProxy;
  # };

  programs.appimage.enable = true;
  # environment.systemPackages = with pkgs; [ocl-icd];

  nixcfg.desktop = true;

  # hm.services.network-manager-applet.enable = true;
  programs.adb.enable = true;

  programs.wireshark.enable = true;
  environment.systemPackages = [pkgs.wireshark pkgs.openfortivpn pkgs.ocl-icd];
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

  boot.binfmt.emulatedSystems = ["aarch64-linux"];

  home-manager.users.alex = {
    dconf.settings = {
      "org/virt-manager/virt-manager".xmleditor-enabled = true;
      "org/virt-manager/virt-manager/connections".uris = ["qemu+ssh://alex@whale/system" "qemu:///system"];
      "org/virt-manager/virt-manager/connections".autoconnect = ["qemu:///system"];
    };
    home.packages = [pkgs.virt-manager];
  };
}
