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
    # pkgs.black
    pkgs.isort
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
  ];
}
