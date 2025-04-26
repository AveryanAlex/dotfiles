{
  networking.nftables = {
    enable = true;
    flushRuleset = true;
  };

  networking.firewall = {
    filterForward = true;
  };

  networking.nat = {
    enable = true;
  };
}
