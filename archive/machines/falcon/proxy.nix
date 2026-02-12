{
  services.microsocks = {
    enable = true;
    ip = "10.57.1.20";
  };

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 1080 ];
}
