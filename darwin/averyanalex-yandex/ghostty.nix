{
  home-manager.users.averyanalex.programs.ghostty = {
    enable = true;
    package = null;

    settings.shell-integration-features = "ssh-env,ssh-terminfo";
  };
}
