{ pkgs, ... }:
{
  home.packages = with pkgs; [
    xdg-ninja # clean home dir
    ncdu # disk usage analyze
    htop # simple cpu monitor
    btop # beautiful cpu, net, disk monitor
    smartmontools # SMART data reader
    ripgrep # fast grep
    ripgrep-all # grep any file type
    nmap # open ports analyzer
    yt-dlp # video/audio downloader
    wget # download file
    cloc # count lines of code
    pv # stdout speed
    fd # user-friendly find
    websocat # websocket terminal client
    parallel
    exiftool
    iperf
    arp-scan
    tokei
  ];
}
