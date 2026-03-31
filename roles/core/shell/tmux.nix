{
  hm.programs.tmux = {
    enable = true;
    extraConfig = ''
      set -g extended-keys on
      set -g extended-keys-format csi-u
    '';
  };
}
