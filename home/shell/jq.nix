{ pkgs, ... }:
{
  programs.jq.enable = pkgs.stdenv.hostPlatform.isLinux;
}
