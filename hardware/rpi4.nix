{
  inputs,
  pkgs,
  ...
}:
{
  imports =
    with inputs.self.nixosModules.hardware;
    [
      physical
    ]
    ++ [ inputs.nixos-hardware.nixosModules.raspberry-pi-4 ];

  hardware.raspberry-pi."4" = {
    apply-overlays-dtmerge.enable = true;
    fkms-3d.enable = true;
    bluetooth.enable = true;
  };

  boot.initrd.systemd.tpm2.enable = false; # WORKAROUND: modprobe: FATAL: Module tpm-crb not found in directory /nix/store/cjas9kxgiv518yx3qk35cwykasn7pic0-linux-rpi-6.6.51-stable_20241008-modules/lib/modules/6.6.51

  console.enable = true;
  boot.kernelParams = [
    "console=ttyS0,115200n8"
    "console=ttyAMA0,115200n8"
    "console=tty0"
  ];

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];
}
