{
  pkgs,
  inputs,
  ...
}:
let
  mkNixPak = inputs.nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  sandboxed-prismlauncher = mkNixPak {
    config =
      { sloth, ... }:
      {
        app.package = pkgs.prismlauncher;

        bubblewrap = {
          bind.rw = [
            (sloth.concat' sloth.homeDir "/.local/share/PrismLauncher")
          ];
          sockets = {
            wayland = true;
            pipewire = true;
          };
        };

        etc.sslCertificates.enable = true;
        gpu.enable = true;
        locale.enable = true;
        fonts.enable = true;
      };
  };
in
{
  home-manager.users.alex = {
    home.packages = [ sandboxed-prismlauncher.config.env ];
  };

  # services.syncthing.settings.folders."PrismLauncher" = {
  #   id = "prismlauncher";
  #   path = "/home/alex/.local/share/PrismLauncher";
  #   ignorePerms = false;
  #   devices = ["hamster" "alligator"];
  # };

  persist.state.homeDirs = [ ".local/share/PrismLauncher" ];
}
