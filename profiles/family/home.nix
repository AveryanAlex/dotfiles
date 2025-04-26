{inputs, ...}: {
  imports = [
    inputs.home-manager.nixosModules.default
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    users.olga = {
      programs.home-manager.enable = true;

      home = {
        username = "olga";
        homeDirectory = "/home/olga";
        stateVersion = "23.05";
      };
    };
  };
}
