{
  services.nfs.server = {
    enable = true;
    exports = ''
      /home/alex/tank 10.57.1.40(rw,sync,wdelay,root_squash,nohide,crossmnt)
      /home/alex/tank 10.57.1.41(rw,sync,wdelay,root_squash,nohide,crossmnt)
    '';
  };

  networking.firewall.interfaces."nebula.averyan" = {
    allowedTCPPorts = [2049];
    allowedUDPPorts = [2049];
  };

  # services.samba = {
  #   enable = true;
  #   openFirewall = lib.mkForce false;
  #   settings = {
  #     global = {
  #       workgroup = "WORKGROUP";
  #       "server string" = "whale";
  #       "netbios name" = "whale";
  #       security = "user";
  #       "server min protocol" = "SMB3";
  #       "hosts allow" = "10.57.1.40 10.57.1.41";
  #       "hosts deny" = "0.0.0.0/0";
  #       "guest account" = "nobody";
  #       "map to guest" = "bad user";
  #       "unix extensions" = "yes";
  #       "smb3 unix extensions" = "yes";
  #     };
  #     tank = {
  #       "path" = "/home/alex/tank";
  #       "browseable" = "yes";
  #       "read only" = "no";
  #       "guest ok" = "no";
  #       "create mask" = "0644";
  #       "directory mask" = "0755";
  #       "force user" = "alex";
  #       "force group" = "users";
  #     };
  #   };
  # };

  # networking.firewall.interfaces."nebula.averyan" = {
  #   allowedTCPPorts = [139 445];
  #   allowedUDPPorts = [137 138];
  # };

  # persist.state.dirs = ["/var/lib/samba"];
}
