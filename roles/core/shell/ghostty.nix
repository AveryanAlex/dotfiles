{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.ghostty.terminfo ];
}
