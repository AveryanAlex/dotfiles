{
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.self.nixosModules.modules.persist
    inputs.self.nixosModules.modules.nebula-averyan
    ./core
    ./family
    ../profiles/mining.nix
  ];

  i18n.defaultLocale = lib.mkForce "ru_RU.UTF-8";
  persist.username = lib.mkForce "olga";
}
