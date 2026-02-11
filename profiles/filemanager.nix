{ pkgs, ... }:
{
  services.gvfs.enable = true;
  services.gnome.sushi.enable = true;
  home-manager.users.alex = {
    home.packages = with pkgs; [
      nautilus
    ];
  };
}
