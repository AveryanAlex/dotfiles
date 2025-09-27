{ inputs, ... }:
{
  imports =
    [ ./minimal ]
    ++ (
      with inputs.self.nixosModules.profiles;
      with shell;
        [
          direnv
          eza
          fzf
          git
          gpg
          misc-s
          neovim
          zoxide
        ]
        ++ [
          # mining
          # qemu
          agenix
          boot
          filesystems
          hosts
          locale
          logs
          misc-p
          monitoring
          nebula-averyan
          nftables
          nix
          persist
          proxy
          ssh-server
          sudo
          unfree
          userdirs
          users
          vmvariant
          xdg
          yggdrasil
        ]);

  hm.programs.tealdeer = {
    enable = true;
    settings = {
      updates.auto_update = true;
      updates.auto_update_interval_hours = 168;
    };
  };
}
