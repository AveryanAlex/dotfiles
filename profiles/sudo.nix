{
  security.sudo = {
    enable = true;
    execWheelOnly = true;
    wheelNeedsPassword = false;
    extraConfig = ''
      Defaults lecture = never
    '';
  };
}
