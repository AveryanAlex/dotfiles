{
  config,
  pkgs,
  lib,
  ...
}:
let
  defaultProfileName = "Off";
  openrgbService = config.services.hardware.openrgb;
  openrgbBin = lib.getExe openrgbService.package;
  openrgbPort = toString openrgbService.server.port;
in
{
  # boot.kernelModules = ["i2c-dev" "i2c-piix4"];
  # services.udev.packages = [pkgs.openrgb];
  # environment.systemPackages = [pkgs.openrgb];
  services.hardware.openrgb = {
    enable = true;
    startupProfile = defaultProfileName;
  };

  powerManagement.resumeCommands =
    lib.mkIf (openrgbService.enable && openrgbService.startupProfile != null)
      ''
        ${pkgs.coreutils}/bin/sleep 2
        cd /var/lib/OpenRGB
        ${openrgbBin} --client 127.0.0.1:${openrgbPort} --profile ${lib.escapeShellArg openrgbService.startupProfile}
      '';

  boot.blacklistedKernelModules = [ "ee1004" ];
}
