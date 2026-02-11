{
  boot.kernelModules = [ "kvm-intel" ];
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
}
