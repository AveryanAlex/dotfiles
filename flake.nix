{
  description = "AveryanAlex's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-master.url = "github:nixos/nixpkgs";
    # nixpkgs-fork.url = "git+file:///home/alex/projects/averyanalex/nixpkgs";
    # nixpkgs-fork.url = "github:averyanalex/nixpkgs/test";

    # nixcfg.url = "git+file:///home/alex/projects/averyanalex/nixcfg";
    nixcfg.url = "github:averyanalex/nixcfg";

    nixpak = {
      url = "github:nixpak/nixpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:nixos/nixos-hardware";

    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";

    ragenix = {
      url = "github:yaxitech/ragenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    impermanence.url = "github:nix-community/impermanence";
    nur.url = "github:nix-community/NUR";
    # jupyenv = {
    #   url = "github:averyanalex/jupyenv";
    #   inputs = {
    #     # nixpkgs.follows = "nixpkgs";
    #     # nixpkgs-stable.follows = "nixpkgs-stable";
    #     # rust-overlay.follows = "rust-overlay";
    #   };
    # };
    lanzaboote.url = "github:nix-community/lanzaboote";
    mailserver = {
      url = "gitlab:simple-nixos-mailserver/nixos-mailserver/nixos-24.11";
      inputs.nixpkgs-24_11.follows = "nixpkgs-stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    averyanalex-blog = {
      url = "github:averyanalex/blog";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
    memexpert = {
      url = "github:averyanalex/memexpert";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    cpmbot = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      url = "github:averyanalex/matetech-answers-bot";
    };
    gayradarbot = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      url = "github:averyanalex/gayradar";
    };
    anoquebot = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      url = "github:averyanalex/anoquebot";
    };
    picsavbot = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      url = "github:averyanalex/picsavbot";
    };
    bvilovebot = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      url = "github:bvilove/bot/9fd96417da5fd60fb2dd6ad794086048a5621f18";
    };
    bvilovebot-beta = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      url = "github:bvilove/bot";
    };
    infinitytgadminsbot = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      url = "github:averyanalex/infinity-tg-admins-bot/61cc721";
    };
    automm = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      url = "git+ssh://git@github.com/averyanalex/auto-market-maker.git";
    };
    gptoolsbot = {
      # inputs.nixpkgs.follows = "nixpkgs";
      url = "git+ssh://git@github.com/averyanalex/gptoolsbot.git";
    };
    avtor24bot = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "git+ssh://git@github.com/averyanalex/avtor24bot.git";
    };
    aplusmuz-music-scraper = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      url = "git+ssh://git@github.com/averyanalex/aplusmuz-music-scraper.git";
    };
    firesquare-servers = {
      url = "github:fire-square/servers";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixpkgs-stable,
    flake-utils,
    ragenix,
    deploy-rs,
    ...
  }: let
    findModules = dir:
      builtins.concatLists (builtins.attrValues (builtins.mapAttrs
        (name: type:
          if type == "regular"
          then [
            {
              name = builtins.elemAt (builtins.match "(.*)\\.nix" name) 0;
              value = dir + "/${name}";
            }
          ]
          else if
            (builtins.readDir (dir + "/${name}"))
            ? "default.nix"
          then [
            {
              inherit name;
              value = dir + "/${name}";
            }
          ]
          else [
            {
              inherit name;
              value = builtins.listToAttrs (findModules (dir + "/${name}"));
            }
          ])
        (builtins.readDir dir)));
  in
    rec {
      nixosModules.hardware = builtins.listToAttrs (findModules ./hardware);
      nixosModules.modules = builtins.listToAttrs (findModules ./modules);
      nixosModules.profiles = builtins.listToAttrs (findModules ./profiles);
      nixosModules.roles = builtins.listToAttrs (findModules ./roles);

      deploy = {
        remoteBuild = true;
        sshUser = "alex";
        user = "root";
        autoRollback = false;
        magicRollback = false;
        nodes = {
          whale = {
            hostname = "whale.averyan.ru";
            profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.whale;
          };
          hawk = {
            hostname = "hawk.averyan.ru";
            profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.hawk;
          };
          # falcon = {
          # hostname = "falcon";
          # profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.falcon;
          # };
          # lizard = {
          # hostname = "lizard";
          # profiles.system.path = deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.lizard;
          # };
          diamond = {
            hostname = "diamond.averyan.ru";
            profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.diamond;
          };
          # ferret = {
          #   hostname = "192.168.3.130";
          #   profiles.system.path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.ferret;
          # };
        };
      };

      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

      nixosConfigurations =
        (with nixpkgs.lib; let
          hosts = builtins.attrNames (builtins.readDir ./machines);

          mkHost = name: let
            system = builtins.readFile (./machines + "/${name}/system.txt");
          in
            nixosSystem {
              inherit system;
              modules = [
                (import (./machines + "/${name}"))
                {networking.hostName = name;}
              ];
              specialArgs = {inherit inputs;};
            };
        in
          genAttrs hosts mkHost)
        // {
          rpi-image = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
              ({...}: {
                config = {
                  sdImage.compressImage = false;
                  system.stateVersion = "23.05";
                  boot.kernelPackages = nixpkgs.legacyPackages.aarch64-linux.linuxKernel.packages.linux_6_1;
                };
              })
            ];
          };
          orangepizero3-image = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-new-kernel-no-zfs-installer.nix"
              ({
                  pkgs,
                  lib,
                  ...
                }:
                # pkgsCross = import nixpkgs {
                #   system = "x86_64-linux";
                #   # hostPlatform.system = "aarch64-linux";
                #   # buildPlatform.system = "x86_64-linux";
                #   crossSystem = "x86_64-linux";
                # };
                {
                  config = {
                    # nixpkgs.hostPlatform.system = "aarch64-linux";
                    # nixpkgs.buildPlatform.system = "x86_64-linux";
                    sdImage.compressImage = false;
                    system.stateVersion = "23.05";
                    boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.linux_6_1.override {
                      argsOverride = {
                        src = pkgs.fetchFromGitHub {
                          owner = "orangepi-xunlong";
                          repo = "linux-orangepi";
                          rev = "3495b5ee0594566c9fed930b96b1cae90600412e";
                          hash = "sha256-MKlhbqORiwzFe84VEbcHbz4ZfRwNYxK5bZD5AKyopGw=";
                        };
                        kernelPatches = [];
                        version = "6.1.31";
                        modDirVersion = "6.1.31";
                      };
                    }));
                    # nixpkgs.config.allowBroken = true;
                  };
                })
            ];
          };
        };

      images.orangepizero3 = nixosConfigurations.orangepizero3-image.config.system.build.sdImage;
    }
    // flake-utils.lib.eachSystem (with flake-utils.lib.system; [x86_64-linux aarch64-linux])
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = [
          ragenix.packages.${system}.ragenix
          deploy-rs.packages.${system}.deploy-rs
          pkgs.alejandra
          pkgs.nebula
          pkgs.wireguard-tools
        ];
      };
    });
}
