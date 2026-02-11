{
  config,
  modulesPath,
  pkgs,
  ...
}:
{
  imports = [
    (modulesPath + "/profiles/headless.nix")
  ];

  config = {
    # boot.growPartition = true;
    fileSystems."/persist" = {
      device = "/dev/nvme0n1p2";
      fsType = "ext4";
      autoResize = true;
    };
    fileSystems."/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
    };

    boot.extraModulePackages = [
      config.boot.kernelPackages.ena
    ];
    boot.initrd.kernelModules = [ "xen-blkfront" ];
    boot.initrd.availableKernelModules = [ "nvme" ];
    boot.kernelParams = [
      "console=ttyS0,115200n8"
      "random.trust_cpu=on"
    ];

    boot.blacklistedKernelModules = [
      "nouveau"
      "xen_fbfront"
    ];

    boot.loader.grub.device = "nodev";
    boot.loader.grub.efiSupport = true;
    boot.loader.grub.efiInstallAsRemovable = true;
    boot.loader.timeout = 1;
    boot.loader.grub.extraConfig = ''
      serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
      terminal_output console serial
      terminal_input console serial
    '';

    systemd.services."serial-getty@ttyS0".enable = true;
    services.udev.packages = [ pkgs.amazon-ec2-utils ];
    environment.systemPackages = [ pkgs.cryptsetup ];
    networking.timeServers = [ "169.254.169.123" ];
    services.udisks2.enable = false;
  };
}
