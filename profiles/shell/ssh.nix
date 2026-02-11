{
  hm.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks."*" = {
      forwardAgent = false;
      addKeysToAgent = "no";
      compression = false;
      serverAliveInterval = 0;
      serverAliveCountMax = 3;
      hashKnownHosts = false;
      userKnownHostsFile = "~/.ssh/known_hosts";
      controlMaster = "no";
      controlPath = "~/.ssh/master-%r@%n:%p";
      controlPersist = "no";
    };

    matchBlocks."serv1.asc.rssi.ru" = {
      forwardAgent = true;
      user = "averyan";
      hostname = "localhost";
      port = 3122;
    };

    matchBlocks."circles.averyan.ru" = {
          forwardAgent = true;
          user = "ubuntu";
          hostname = "195.209.214.27";
        };
  };
}
