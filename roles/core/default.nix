{
  config,
  inputs,
  lib,
  ...
}:
{
  imports = [
    ./home.nix
    inputs.quadlet-nix.nixosModules.quadlet
    inputs.self.nixosModules.modules.nebula-averyan
    inputs.self.nixosModules.modules.persist
    inputs.self.nixosModules.modules.port-forward
    inputs.self.nixosModules.modules.tproxy
    inputs.self.nixosModules.modules.xray
    inputs.self.nixosModules.modules.mihomo
    ./network.nix
    ./podman.nix
    ./hosts.nix
    ./shell
    ./system.nix
    ./mihomo.nix
  ];

  documentation.info.enable = false;

  users.users.alex.extraGroups = lib.optional config.programs.wireshark.enable "wireshark";

  # boot.tmp.useTmpfs = true;

  boot.kernelModules = [ "tcp_bbr" ];

  time.timeZone = "Europe/Moscow";

  security.polkit.enable = true;

  services.dbus.implementation = "broker";

  services.irqbalance.enable = true;

  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';

  networking.tproxy.enable = true;

  # Tealdeer
  hm.programs.tealdeer = {
    enable = true;
    settings = {
      updates.auto_update = true;
      updates.auto_update_interval_hours = 168;
    };
  };
}
