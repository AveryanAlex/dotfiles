{
  pkgs,
  config,
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
    cpu.amd
    gpu.amd
  ]);

  # STORAGE
  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "uas"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  services.lvm.boot.thin.enable = true;

  # SCREEN
  # brightness control
  environment.systemPackages = [ pkgs.ddcutil ];
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  boot.kernelModules = [ "ddcci" ];

  boot.kernelParams = [
    "video=DP-1:3440x1440@144"
  ];
  hm = {
    wayland.windowManager.sway.config.output.DP-1 = {
      mode = "3440x1440@144Hz";
      scale = "1.25";
      adaptive_sync = "off";
    };
    wayland.windowManager.hyprland.extraConfig = ''
      monitor=DP-1,3440x1440@144,0x0,1
    '';
  };
  boot.loader.systemd-boot.consoleMode = "max";
}
