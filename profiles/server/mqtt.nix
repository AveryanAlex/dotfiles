{
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        users = {
          switch = {
            acl = [ "readwrite #" ];
            password = "switch";
          };
        };
      }
    ];
  };

  networking.firewall.interfaces.lan0.allowedTCPPorts = [ 1883 ];
}
