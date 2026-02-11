{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    lm_sensors
  ];

  services.fwupd.enable = true;
}
