{
  config,
  lib,
  ...
}:
{
  # users = {
  #   users.yggdrasil = {
  #     isSystemUser = true;
  #     description = "Yggdrasil";
  #     group = "yggdrasil";
  #     uid = 728;
  #   };
  #   groups.yggdrasil.gid = 728;
  # };

  # systemd.services.yggdrasil = {
  #   serviceConfig = {
  #     DynamicUser = lib.mkForce false;
  #     User = "yggdrasil";
  #   };
  # };

  age.secrets.yggdrasil-keys = {
    file = ../secrets/yggdrasil/${config.networking.hostName}.age;
    # owner = "yggdrasil";
    # group = "yggdrasil";
  };
  # services.yggdrasil.settings.PrivateKeyPath = config.age.secrets.yggdrasil-keys.path;
}
