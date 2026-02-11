{pkgs, ...}: {
  # boot.kernelModules = ["i2c-dev" "i2c-piix4"];
  # services.udev.packages = [pkgs.openrgb];
  # environment.systemPackages = [pkgs.openrgb];
  services.hardware.openrgb = {
    enable = true;
    startupProfile = "Off";
  };
  boot.blacklistedKernelModules = ["ee1004"];
}
