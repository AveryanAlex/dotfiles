{
  config,
  inputs,
  lib,
  ...
}:
{
  nixpkgs.overlays =
    lib.mapAttrsToList
      (name: input: _final: prev: {
        ${lib.removePrefix "nixpkgs-" name} = import input {
          system = prev.stdenv.hostPlatform.system;
          config = config.nixpkgs.config;
        };
      })
      (
        # pkgs.kernel would collide with callPackage's optional kernel arguments.
        # The pinned kernel input is accessed directly by its consumers instead.
        lib.filterAttrs (name: _: lib.hasPrefix "nixpkgs-" name && name != "nixpkgs-kernel") inputs
      );
}
