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
      gt = inputs.gastown.packages.${prev.system}.gt;
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

    gt
  ]);

  persist.cache.homeDirs = [ ".local/share/uv" ];
}
