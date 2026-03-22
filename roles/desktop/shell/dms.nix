{ inputs, ... }:
{
  imports = [ inputs.dms.nixosModules.dank-material-shell ];

  programs.dank-material-shell.enable = true;

  hm = {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms.homeModules.niri
    ];

    programs.dank-material-shell = {
      enable = true;

      # Niri integration
      niri = {
        enableKeybinds = true;
        enableSpawn = true;
        includes.filesToInclude = [
          "binds"
          "colors"
          "layout"
          "outputs"
          "wpblur"
          "alttab"
        ];
      };

      # Do NOT enable systemd — mutually exclusive with niri.enableSpawn
    };
  };
}
