{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.default
    (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" "alex" ])
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.alex = {
      programs.home-manager.enable = true;
      home = {
        username = "alex";
        homeDirectory = "/home/alex";
        stateVersion = config.system.stateVersion;
      };
    };
  };
}
