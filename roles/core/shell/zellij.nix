{
  hm.programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      default_shell = "zsh";
      serialization_interval = 60;
      scroll_buffer_size = 100000;
      pane_frames = false;
      on_force_close = "detach";
      show_startup_tips = false;
    };
  };
}
