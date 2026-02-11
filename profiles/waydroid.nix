{
  virtualisation.waydroid.enable = true;

  networking.nat.internalInterfaces = [ "waydroid0" ];

  persist.state.dirs = [ "/var/lib/waydroid" ];
  persist.state.homeDirs = [ ".local/share/waydroid" ];
}
