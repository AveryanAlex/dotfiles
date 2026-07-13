{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  services.qdrant = {
    enable = true;
    # Current nixpkgs fails to compile Qdrant with an LLVM AVX-512 selector error.
    # This normal nixpkgs revision provides the last known-good Qdrant 1.18.2 build.
    package = inputs.nixpkgs-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.qdrant;
  };

  systemd.services.qdrant.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "qdrant";
    MemoryMax = "4G";
  };

  users.users.qdrant = {
    isSystemUser = true;
    description = "Qdrant";
    group = "qdrant";
    uid = 628;
  };
  users.groups.qdrant.gid = 628;

  persist.state.dirs = [
    {
      directory = "/var/lib/qdrant";
      mode = "u=rwx,g=rx,o=";
      user = "qdrant";
      group = "qdrant";
    }
  ];
}
