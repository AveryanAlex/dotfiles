{
  pkgs,
  ...
}:
{
  home-manager.users.alex = {
    home.packages = with pkgs; [
      xdg-ninja # clean home dir
      ncdu # disk usage analyze
      killall # kill all processes by name
      btop # beautiful cpu, net, disk monitor
      htop # simple cpu monitor
      smartmontools # SMART data reader
      usbutils # lsusb
      pciutils # lspci
      traceroute # show route trace to host
      unzip # unarchive zip
      # rmlint # find dupes
      fastfetch # system info
      ripgrep # fast grep
      stable.ripgrep-all # grep any file type
      iotop # disk usage monitor
      nmap # open ports analyzer
      stress # cpu stress test
      screen # run in background
      hashcat # password cracking
      micro # simple text editor
      bedtools # genome arithmetic toolkit
      compsize # btrfs compression info
      yt-dlp # video/audio downloader
      untrunc-anthwlock # repair truncated mp4/mov
      wget # download file
      cloc # count lines of code
      pv # stdout speed
      fd # user-friendly find
      websocat # websocket terminal client
      payload-dumper-go
      parallel
      beep
      exiftool
      lsof
      iperf
      rmlint
      immich-cli
    ];

    home.sessionVariables = {
      EDITOR = "micro";
    };
  };

  environment.systemPackages = [ pkgs.perf ];
}
