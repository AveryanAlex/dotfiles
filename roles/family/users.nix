{
  config,
  secrets,
  ...
}:
{
  age.secrets.password-alex.file = "${secrets}/passwords/alex.age";
  age.secrets.password-olga.file = "${secrets}/passwords/olga.age";

  users = {
    mutableUsers = false;
    users = {
      alex = {
        isNormalUser = true;
        description = "Alexander Averyanov";
        extraGroups = [ "wheel" ];
        uid = 1000;
        hashedPasswordFile = config.age.secrets.password-alex.path;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDP6BYhOQG5swda8e3YRo4LqhdNNAQd3NwkQME193izZ alex@averyan.ru"
        ];
      };
      olga = {
        isNormalUser = true;
        description = "Olga";
        extraGroups = [ "wheel" ];
        uid = 1038;
        hashedPasswordFile = config.age.secrets.password-olga.path;
      };
    };
  };
}
