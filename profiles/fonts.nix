{ pkgs, ... }:
{
  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      corefonts # Proprietary: Times New Roman, etc
      jetbrains-mono
      meslo-lgs-nf
      monaspace
      noto-fonts
      noto-fonts-cjk-sans
      roboto
      source-sans
      source-sans-pro
      font-awesome
      inter
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "MesloLGS NF" ];
      };
    };
  };
}
