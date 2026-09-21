{ pkgs, ... }:
{
  home.packages = with pkgs; [
    stress # cpu stress test
    hashcat # password cracking
    bedtools # genome arithmetic toolkit
    untrunc-anthwlock # repair truncated mp4/mov
    payload-dumper-go
    rmlint
    immich-cli
  ];
}
