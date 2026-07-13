{
  pkgs,
  lib,
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

  # Keep the patched Zen kernel stable across main nixpkgs updates.
  boot.kernelPackages = lib.mkForce (
    inputs."nixpkgs-kernel".legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxKernel.packages.linux_zen
  );

  # SCREEN
  # brightness control
  environment.systemPackages = [ pkgs.ddcutil ];
  boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
  boot.kernelModules = [ "ddcci" ];
  # Xiaomi Mi Monitor (XMI3444) advertises a 48-144 Hz EDID VRR range,
  # but keeps the AMDGPU DP DPCD FreeSync gate disabled when the OSD is stuck.
  # Force VRR for this EDID and clamp the effective floor to 70 Hz to avoid
  # low-refresh edge color artifacts.
  boot.kernelPatches = [
    {
      name = "amdgpu-xmi3444-force-vrr";
      patch = ./amdgpu-xmi3444-force-vrr.patch;
    }
  ];

  boot.kernelParams = [
    "video=DP-1:3440x1440@144"
  ];
  hm = {
    programs.niri.settings.debug.skip-cursor-only-updates-during-vrr = [ ];
    programs.niri.settings.outputs."DP-1" = {
      mode = {
        width = 3440;
        height = 1440;
        refresh = 144.0;
      };
      scale = 1.25;
      variable-refresh-rate = "on-demand";
      position = {
        x = 0;
        y = 0;
      };
    };
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
