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

      # DMS keybinds injected directly into niri settings (no includes hack)
      # Provides: Mod+Space (launcher), Mod+N (notifications), Mod+V (clipboard),
      #   Mod+Comma (settings), Mod+P (notepad), Super+Alt+L (lock), Mod+X (power menu),
      #   Mod+M (process list), Mod+Alt+N (night mode), XF86Audio*, XF86MonBrightness*
      niri = {
        enableKeybinds = true;
        includes.enable = false;
      };
    };
  };
}
