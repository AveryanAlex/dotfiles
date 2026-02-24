{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./vscode.nix
    ./zed.nix
    ./nbconvert.nix
    ./docker.nix
    ./opencode.nix
    ./claudecode.nix
    ./mcp.nix
  ];

  nixpkgs.overlays = [
    (final: prev: {
      gastown = inputs.gastown.packages.${prev.system}.gt;
      beads = inputs.beads.packages.${prev.system}.default;
      dolt = prev.dolt.overrideAttrs (old: rec {
        version = "1.82.4";
        src = prev.fetchFromGitHub {
          owner = "dolthub";
          repo = "dolt";
          tag = "v${version}";
          hash = "sha256-mavL3y+Kv25hzFlDFXk7W/jeKVKlCBjlc67GkL3Jcwk=";
        };
        vendorHash = "sha256-K1KzsqptZxO5OraWKIXeqKuVSzb6E/Mjy3c5PQ7Rs9k=";
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ prev.pkg-config ];
        buildInputs = (old.buildInputs or [ ]) ++ [ prev.icu ];
      });
    })
  ];

  hm.home.packages = [
    ((import ./python.nix) pkgs)
  ]
  ++ (with pkgs; [
    nixd
    nil
    nixfmt
    nixfmt-tree

    # clang
    llvmPackages.libclang
    llvm.dev
    # clang-tools
    lldb
    gdb

    pkg-config
    libx11

    rustup

    uv

    pnpm
    nodejs_latest

    code-cursor
    # devcontainer TODO: re-add once fixed
    # antigravity

    jdk
    maven

    automake

    bun
    openssl

    beads
    dolt
    gastown
  ]);

  persist.cache.homeDirs = [ ".local/share/uv" ];
}
