{ pkgs, ... }:
{
  home-manager.users.alex = {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;

      nix-direnv.enable = true;

      config.whitelist.prefix = [ "~/gt" ];
    };

    home.packages = [ pkgs.devenv ];
  };

  persist.state.homeDirs = [ ".local/share/direnv" ];
}
