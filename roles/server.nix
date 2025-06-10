{pkgs, ...}: {
  imports = [
    ./full.nix
  ];

  systemd = {
    enableEmergencyMode = false;

    watchdog = {
      runtimeTime = "30s";
      rebootTime = "10m";
    };

    sleep.extraConfig = ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  systemd.targets.network-online.wantedBy = ["multi-user.target"];
  systemd.network.wait-online.enable = true;

  hm.services.gpg-agent.pinentryPackage = pkgs.pinentry-curses;
}
