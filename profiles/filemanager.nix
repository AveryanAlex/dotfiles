{ pkgs, ... }:
{
  services.gvfs.enable = true;
  services.gnome.sushi.enable = true;
  home-manager.users.alex = {
    home.packages = with pkgs; [
      nautilus
    ];

    home.file.".config/gtk-3.0/bookmarks".text = ''
      file:///home/alex/projects Projects
      file:///tank Tank
      file:///home/alex/Documents
      file:///home/alex/Pictures
      file:///home/alex/Downloads
    '';
  };
}
