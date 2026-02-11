{ lib, ... }:
{
  services.uptime-kuma = {
    enable = true;
    appriseSupport = true;
  };

  users = {
    users.uptime-kuma = {
      isSystemUser = true;
      description = "Uptime Kuma";
      group = "uptime-kuma";
      uid = 836;
    };
    groups.uptime-kuma.gid = 836;
  };

  systemd.services.uptime-kuma = {
    serviceConfig = {
      DynamicUser = lib.mkForce false;
      User = "uptime-kuma";
    };
  };

  persist.state.dirs = [
    {
      directory = "/var/lib/uptime-kuma";
      user = "uptime-kuma";
      group = "uptime-kuma";
      mode = "u=rwx,g=rx,o=rx";
    }
  ];
}
