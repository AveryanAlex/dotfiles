{
  hm.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings."*" = {
      ForwardAgent = false;
      AddKeysToAgent = "yes";
      Compression = false;
      ServerAliveInterval = 0;
      ServerAliveCountMax = 3;
      HashKnownHosts = false;
      UserKnownHostsFile = "~/.ssh/known_hosts";
      ControlMaster = "no";
      ControlPath = "~/.ssh/master-%r@%n:%p";
      ControlPersist = "no";
      # Only use keys from the agent or explicit IdentityFile — don't probe default paths
      IdentitiesOnly = "yes";
    };

    settings."serv1.asc.rssi.ru" = {
      ForwardAgent = true;
      User = "averyan";
      HostName = "whale";
      Port = 3122;
    };

    settings."circles.averyan.ru" = {
      ForwardAgent = true;
      User = "ubuntu";
      HostName = "195.209.218.189";
    };
  };
}
