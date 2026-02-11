{ config, ... }:
{
  boot.kernelModules = [ "kvm-amd" ];
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  powerManagement.cpuFreqGovernor = "schedutil";

  boot.extraModulePackages = [ config.boot.kernelPackages.zenpower ];
}
