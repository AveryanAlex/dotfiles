{inputs, ...}: {
  imports =
    (with inputs.self.nixosModules.modules; [
      nebula-averyan
      persist
    ])
    ++ (with inputs.self.nixosModules.profiles; [
      agenix
      boot
      filesystems
      hosts
      locale
      logs
      misc-p
      monitoring
      nebula-averyan
      nftables
      persist
      shell.eza
      shell.zsh
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
    ];

  nixcfg.inputs = inputs;
  nixcfg.username = "alex";

  networking = {
    nameservers = ["95.165.105.90#dns.neutrino.su"];
    search = ["n.averyan.ru"];
    useDHCP = false;
    useNetworkd = true;
  };
  services.avahi.enable = false;

  zramSwap = {
    enable = true;
    memoryPercent = 40;
  };

  time.timeZone = "Europe/Moscow";

  security.polkit.enable = true;
}
