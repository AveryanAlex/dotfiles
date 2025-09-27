{
  nixpkgs.localSystem = {
    gcc.arch = "x86-64-v2";
    gcc.tune = "znver3";
    system = "x86_64-linux";
  };
  nix.settings.system-features = [
    "big-parallel"
    "gccarch-x86-64-v2"
  ];
}
