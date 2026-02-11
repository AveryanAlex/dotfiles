{ config, ... }:
{
  age.secrets.mqtt-password.file = ../../secrets/intpass/mqtt-password.age;

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 1883 ];

  services.mosquitto = {
    enable = true;

    listeners = [
      {
        users.root = {
          acl = [
            "readwrite #"
          ];
          hashedPasswordFile = config.age.secrets.mqtt-password.path;
        };
      }
    ];
  };
}
