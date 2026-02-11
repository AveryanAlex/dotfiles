{
  # enable distrobox
  hm.programs.distrobox.enable = true;

  # separate home by default
  hm.home.sessionVariables.DBX_CONTAINER_HOME_PREFIX = "/home/alex/Distrobox";

  # convenient aliases to enter containers
  hm.home.shellAliases = {
    arch = "distrobox enter archlinux";
    deb = "distrobox enter ubuntu";
  };
}
