{
  services.hydra = {
    enable = true;
    hydraURL = "https://hydra.averyan.ru";
    notificationSender = "hydra@localhost";
    buildMachinesFiles = [ ];
    useSubstitutes = true;
    port = 2875;
  };

  nix.settings.allowed-users = [ "hydra" ];

  persist.state.dirs = [
    {
      directory = "/var/lib/hydra";
      user = "hydra";
      group = "hydra";
      mode = "u=rwx,g=rx,o=";
    }
  ];

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ 2875 ];
}
