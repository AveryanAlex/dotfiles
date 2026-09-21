{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    daemon.enable = true;
    settings = {
      enter_accept = false;
      stats.common_prefix = [
        "sudo"
        "_"
      ];
      sync.records = true;
    };
  };
}
