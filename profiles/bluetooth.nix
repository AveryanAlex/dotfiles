{
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  persist.state.dirs = [ "/var/lib/bluetooth" ];
}
