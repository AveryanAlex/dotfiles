{ pkgs, ... }:
{
  hardware.rtl-sdr.enable = true;
  users.users.alex.extraGroups = [ "plugdev" ];
  home-manager.users.alex = {
    home.packages = with pkgs; [
      # gqrx TODO: re-add once fixed
    ];
  };
}
