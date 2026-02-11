{
  inputs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ]
  ++ (with inputs.self.nixosModules.hardware; [
    physical
    sdboot
    cpu.intel
    gpu.intel
  ]);

  # Storage
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "vmd"
    "nvme"
    "usb_storage"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];

  # Laptop
  hardware.sensor.iio.enable = true;
  hardware.bluetooth.enable = true;
  services.upower.enable = true;
  powerManagement.cpuFreqGovernor = "powersave";
}
