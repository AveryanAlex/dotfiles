{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  base16-schemes = pkgs.fetchFromGitHub {
    owner = "tinted-theming";
    repo = "base16-schemes";
    rev = "42d74711418db38b08575336fc03f30bd3799d1d";
    sha256 = "ZSul9NpLbRgMIla+IIijFwGWZhx+ShfY2KzNicLG8jY=";
  };
in
{
  imports = [
    inputs.stylix.nixosModules.stylix
  ];

  stylix = {
    image = ../../wallpaper.jpg;
    polarity = "dark";

    base16Scheme = "${base16-schemes}/dracula.yaml";

    fonts = {
      monospace = {
        name = "MesloLGS NF";
        package = pkgs.meslo-lgs-nf;
      };
    };
  };
}
