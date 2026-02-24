{
  pkgs,
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

  # nixpkgs.overlays = [ inputs.fenix.overlays.default ];

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
    devcontainer
    # antigravity

    jdk
    maven

    automake

    bun
    openssl
  ]);

  persist.cache.homeDirs = [ ".local/share/uv" ];
}
