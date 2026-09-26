{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ./ghostty.nix
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.enable = false;

  fonts.packages = with pkgs; [
    meslo-lgs-nf
    monaspace
  ];

  environment.systemPath = [ "/usr/local/jamf/bin" ];

  homebrew = {
    enable = true;
    enableZshIntegration = true;

    taps = [ "gromgit/fuse" ];

    brews = [
      "gromgit/fuse/sshfs-mac"
      "minio-mc"
      "nebula"
      "node"
      "pnpm"
      "rustup"
    ];

    casks = [
      "chatgpt"
      "firefox"
      "ghostty"
      "hammerspoon"
      "openmtp"
      "shottr"
      "steam"
      "telegram"
      "visual-studio-code"
      "yandex-music"
      "prismlauncher"
    ];

    onActivation.cleanup = "uninstall";
  };

  programs.zsh.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;

  system = {
    primaryUser = "averyanalex";
    stateVersion = 6;
  };

  users.users.averyanalex = {
    name = "averyanalex";
    home = "/Users/averyanalex";
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };

    users.averyanalex = {
      imports = [
        ../../home/apps/orca-slicer
        ../../home/shell
        ../../home/shell/fastfetch.nix
      ];

      home = {
        username = "averyanalex";
        homeDirectory = "/Users/averyanalex";
        stateVersion = "26.05";

        sessionPath = [
          "/Users/averyanalex/.local/bin"
          "/opt/homebrew/opt/rustup/bin"
        ];

        sessionVariables.NODE_EXTRA_CA_CERTS = "/Users/averyanalex/.claude/yandex-ca.pem";
      };

      programs.git.signing.signByDefault = lib.mkForce false;
      programs.home-manager.enable = true;
      programs.ssh.settings = {
        yandex-ml-inference = inputs.home-manager.lib.hm.dag.entryBefore [ "yandex" ] {
          header = "Host ml-inference-gpu-vm-a100-4.sas.yp-c.yandex.net";
          HostName = "ml-inference-gpu-vm-a100-4.sas.yp-c.yandex.net";
          IdentityAgent = "~/.skotty/sock/default.sock";
          ForwardAgent = "~/.skotty/sock/default.sock";
          IdentitiesOnly = "no";
        };

        yandex = {
          header = "Host *.yandex.net";
          IdentityAgent = "~/.skotty/sock/default.sock";
          ForwardAgent = "~/.skotty/sock/sudo.sock";
          IdentitiesOnly = "no";
        };

        "github.com" = {
          User = "git";
          IdentityAgent = "~/.skotty/sock/default.sock";
          IdentitiesOnly = "yes";
          IdentityFile = "~/.ssh/skotty_legacy.pub";
        };
      };
      programs.zsh.shellAliases.upd = "sudo darwin-rebuild switch --flake '.#averyanalex-yandex'";
    };
  };
}
