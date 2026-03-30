{ lib, ... }:
{
  hm.home.sessionPath = [
    "/home/alex/.npm-global/bin"
  ];

  hm.home.sessionVariables.NODE_PATH = "/home/alex/.npm-global/lib/node_modules";

  hm.home.file.".npmrc".text = ''
    prefix=/home/alex/.npm-global
  '';
}
