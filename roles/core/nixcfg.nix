{ inputs, ... }:
{
  imports = [
    inputs.nixcfg.nixosModules.default
    (
      { lib, config, ... }@args:
      let
        upstream = import "${inputs.nixcfg}/nixos" args;
      in
      upstream
      // {
        # nixcfg still selects scripted initrd, which NixOS 26.11 removed.
        config = lib.recursiveUpdate upstream.config {
          boot.initrd.systemd.enable = lib.mkIf false true;
        };
      }
    )
  ];

  disabledModules = [ "${inputs.nixcfg}/nixos" ];
}
