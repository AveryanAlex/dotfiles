{pkgs, ...}: {
  hardware.graphics = {
    enable = true;
    # driSupport32Bit = true;

    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
    ];
  };
}
