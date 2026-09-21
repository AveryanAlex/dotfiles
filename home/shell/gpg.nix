{
  services.gpg-agent = {
    enable = true;
    # enableSshSupport = true;
  };

  programs.gpg = {
    enable = true;
    mutableKeys = false;
    mutableTrust = false;
    publicKeys = [
      {
        source = ./gpg/averyanalex.asc;
        trust = 5;
      }
      {
        source = ./gpg/cofob.asc;
        trust = 4;
      }
      {
        source = ./gpg/qubes.asc;
        trust = 4;
      }
    ];
  };
}
