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

  # Pre-seed empty DMS include files so niri can start before `dms setup`
  systemd.tmpfiles.rules = [
    "d /home/alex/.config/niri/dms 0755 alex users -"
    "f /home/alex/.config/niri/dms/binds.kdl 0644 alex users -"
    "f /home/alex/.config/niri/dms/colors.kdl 0644 alex users -"
    "f /home/alex/.config/niri/dms/layout.kdl 0644 alex users -"
    "f /home/alex/.config/niri/dms/outputs.kdl 0644 alex users -"
    "f /home/alex/.config/niri/dms/wpblur.kdl 0644 alex users -"
    "f /home/alex/.config/niri/dms/alttab.kdl 0644 alex users -"
  ];
}
