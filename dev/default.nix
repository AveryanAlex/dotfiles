{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./vscode.nix
    ./nbconvert.nix
  ];

  nixpkgs.overlays = [inputs.fenix.overlays.default];

  hm.home.packages = [
    ((import ./python.nix) pkgs)
    # pkgs.fenix.complete
    pkgs.clang
    (pkgs.fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    pkgs.gdb
    # pkgs.aider-chat-with-playwright
    pkgs.uv
    pkgs.pnpm_10
    pkgs.nodejs_latest
    pkgs.code-cursor
  ] ++ (with pkgs; [
  	nixd
  	nixfmt-rfc-style
  ]);

  persist.cache.homeDirs = [".local/share/uv"];
}
