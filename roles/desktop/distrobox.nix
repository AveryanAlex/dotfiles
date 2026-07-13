{ pkgs, ... }: {
  hm = {
    # enable distrobox
    programs.distrobox = {
      enable = true;
      settings = {
        container_manager = "lilipod";
      };
    };

    home.packages = with pkgs; [ lilipod ];

    # separate home by default
    home.sessionVariables.DBX_CONTAINER_HOME_PREFIX = "/home/alex/Distrobox";

    # convenient aliases to enter containers
    home.shellAliases = {
      arch = "distrobox enter archlinux";
      deb = "distrobox enter ubuntu";
    };
  };
}
