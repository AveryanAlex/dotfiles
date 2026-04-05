{
  config,
  secrets,
  ...
}:
{
  age.secrets.yggdrasil-keys = {
    file = "${secrets}/yggdrasil/${config.networking.hostName}.age";
  };
  services.yggdrasil.settings.PrivateKeyPath = config.age.secrets.yggdrasil-keys.path;
}
