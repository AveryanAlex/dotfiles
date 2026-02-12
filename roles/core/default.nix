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
    memoryPercent = 60;
  };

  time.timeZone = "Europe/Moscow";

  security.polkit.enable = true;

  services.dbus.implementation = "broker";

  services.irqbalance.enable = true;

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
