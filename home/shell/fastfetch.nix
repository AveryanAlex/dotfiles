{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.fastfetch ];

  programs.zsh.initContent = lib.mkAfter ''
    if [[ -o interactive ]] && command -v fastfetch >/dev/null; then
      fastfetch
    fi
  '';
}
