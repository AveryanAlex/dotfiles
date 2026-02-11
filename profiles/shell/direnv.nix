{ pkgs, ... }:
{
  home-manager.users.alex = {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;

      nix-direnv.enable = true;
    };

    home.packages = [ pkgs.devenv ];
  };

  persist.state.homeDirs = [ ".local/share/direnv" ];
}
