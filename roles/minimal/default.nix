{
  inputs,
  ...
}:
{
  imports =
    (with inputs.self.nixosModules.modules; [
      nebula-averyan
      persist
    ])
    ++ (with inputs.self.nixosModules.profiles; [
      agenix
      boot
      filesystems
      locale
      logs
      misc-p
      monitoring
      nebula-averyan
      persist
      shell.eza
      shell.zsh
      shell.ssh
      ssh-server
      sudo
      unfree
      unsecure
      userdirs
      users
      vmvariant
      xdg
      yggdrasil
    ])
    ++ [
      inputs.nixcfg.nixosModules.default
      inputs.home-manager.nixosModules.default
      ./network.nix
      ./podman.nix
      ./hosts.nix
    ];

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
}
