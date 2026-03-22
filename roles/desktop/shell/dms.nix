{ inputs, ... }:
{
  imports = [ inputs.dms.nixosModules.dank-material-shell ];

  # DMS NixOS module provides:
  #   - security.polkit (system polkit daemon)
  #   - services.power-profiles-daemon
  #   - services.accounts-daemon
  #   - quickshell in environment.systemPackages
  programs.dank-material-shell.enable = true;

  hm = {
    imports = [
      inputs.dms.homeModules.dank-material-shell
      inputs.dms.homeModules.niri
    ];

    programs.dank-material-shell = {
      enable = true;

      # Systemd user service: auto-restarts on crash, restarts on config change
      systemd.enable = true;

      # DMS keybinds are defined manually in niri.nix for full control.
      # Do not enable enableKeybinds — it injects a hardcoded non-customizable set.
      niri.includes.enable = false;
    };
  };
}
