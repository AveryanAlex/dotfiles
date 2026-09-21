{ lib, pkgs, ... }:
{
  config = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    home-manager.users.alex.home.packages = with pkgs; [
      killall # kill all processes by name
      usbutils # lsusb
      pciutils # lspci
      traceroute # show route trace to host
      unzip # unarchive zip
      zip
      iotop # disk usage monitor
      screen # run in background
      compsize # btrfs compression info
      beep
      lsof
    ];

    environment.systemPackages = with pkgs; [
      perf
      tcpdump # packet sniffer (root tool, needs to be in system PATH for sudo)
    ];
  };
}
