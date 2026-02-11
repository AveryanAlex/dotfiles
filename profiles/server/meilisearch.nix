{ lib, ... }:
{
  services.meilisearch = {
    enable = true;
  };

  systemd.services.meilisearch.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "meilisearch";
  };

  users.users.meilisearch = {
    isSystemUser = true;
    description = "Meilisearch";
    group = "meilisearch";
    uid = 638;
  };
  users.groups.meilisearch.gid = 638;

  persist.state.dirs = [
    {
      directory = "/var/lib/meilisearch";
      mode = "u=rwx,g=rx,o=";
      user = "meilisearch";
      group = "meilisearch";
    }
  ];
}
