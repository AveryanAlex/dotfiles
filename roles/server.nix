{ pkgs, ... }:
{
  imports = [
    ./core
  ];

  systemd = {
    enableEmergencyMode = false;

    settings = {
      Manager.RebootWatchdogSec = "10m";
      Manager.RuntimeWatchdogSec = "30s";
    };

    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  systemd.targets.network-online.wantedBy = [ "multi-user.target" ];
  systemd.network.wait-online.enable = true;

  hm.services.gpg-agent.pinentry.package = pkgs.pinentry-curses;
}
