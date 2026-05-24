{
  pkgs,
  ...
}:
let
  # Some integrations still hardcode pyright binaries, so keep compat shims.
  pyrightCompat = pkgs.writeShellScriptBin "pyright" ''
    exec ${pkgs.basedpyright}/bin/basedpyright "$@"
  '';
  pyrightLangserverCompat = pkgs.writeShellScriptBin "pyright-langserver" ''
    exec ${pkgs.basedpyright}/bin/basedpyright-langserver "$@"
  '';
in
{
  imports = [
    ./vscode.nix
    ./zed.nix
    ./nbconvert.nix
    ./docker.nix
    ./npm.nix
    ./opencode.nix
    ./codex.nix
    ./claudecode.nix
    ./mcp.nix
  ];

  hm.home.packages = [
    ((import ./python.nix) pkgs)
    pyrightCompat
    pyrightLangserverCompat
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
    gcc
    cmake
    gnumake
    automake

    pkg-config
    libx11

    rustup

    uv

    pnpm
    nodejs_latest
    basedpyright
    typescript-language-server

    code-cursor
    # devcontainer TODO: re-add once fixed
    # antigravity

    jdk
    maven

    bun
    openssl
    sqlite
    typst

    kaggle

    rtk
  ]);

  hm.home.sessionVariables.CARGO_TARGET_DIR = "/home/alex/.cargo/target";
  hm.home.sessionVariables.MYPY_CACHE_DIR = "/home/alex/.cache/mypy";
  hm.home.sessionVariables.RUFF_CACHE_DIR = "/home/alex/.cache/ruff";

  persist.cache.homeDirs = [
    ".local/share/uv"
    ".cargo/target"
  ];

  hm.home.sessionPath = [
    "/home/alex/.cargo/bin"
  ];
}
