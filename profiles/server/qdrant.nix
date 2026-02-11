{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  services.qdrant = {
    enable = true;
  };

  systemd.services.qdrant.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "qdrant";
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
