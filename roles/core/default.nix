{
  inputs,
  ...
}:
{
  imports = [
    inputs.nixcfg.nixosModules.default
    inputs.home-manager.nixosModules.default
    inputs.quadlet-nix.nixosModules.quadlet
    inputs.self.nixosModules.modules.nebula-averyan
    inputs.self.nixosModules.modules.persist
    inputs.self.nixosModules.modules.tproxy
    inputs.self.nixosModules.modules.xray
    ./network.nix
    ./podman.nix
    ./hosts.nix
    ./shell
    ./system.nix
  ];

  # Core system configuration
  security.audit.enable = true;
  security.auditd.enable = true;

  nixcfg.inputs = inputs;
  nixcfg.username = "alex";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 60;
  };

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
