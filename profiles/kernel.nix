{
  pkgs,
  config,
  ...
}:
{
  boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
  boot.extraModulePackages = [ config.boot.kernelPackages.amneziawg ];
}
