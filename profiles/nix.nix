{
  nix = {
    # gc = {
    #   automatic = true;
    #   dates = "04:15";
    #   randomizedDelaySec = "1800";
    #   options = "--delete-older-than 7d";
    # };
  };

  environment.sessionVariables.NIX_REMOTE = "daemon";

  systemd.services.nix-daemon = {environment.TMPDIR = "/nix/tmp";};
  systemd.tmpfiles.rules = ["d /nix/tmp 0755 root root 1d"];
}
