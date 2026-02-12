{ pkgs, ... }:
{
  hm = {
    programs.wezterm = {
      enable = true;
      package = pkgs.wezterm;
      enableZshIntegration = true;

      extraConfig = ''
        return {
          front_end = "WebGpu"
        }
      '';
    };
  };
}
