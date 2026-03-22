{ pkgs, ... }:
{
  security.wrappers = {
    nethogs = {
      source = "${pkgs.nethogs}/bin/nethogs";
      capabilities = "cap_net_admin=ep cap_net_raw=ep";
      owner = "root";
      group = "root";
      permissions = "u+rx,g+x,o+x";
    };
  };
  environment.systemPackages = [ pkgs.nethogs ];
}
