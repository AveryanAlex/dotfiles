{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    settings = {
      "*" = {
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
        # Only use keys from the agent or explicit IdentityFile — don't probe default paths.
        IdentitiesOnly = "yes";
      };

      "serv1.asc.rssi.ru" = {
        ForwardAgent = true;
        User = "averyan";
        HostName = "mole";
        HostKeyAlias = "serv1.asc.rssi.ru";
        Port = 3122;
      };

      "serv2.asc.rssi.ru" = {
        ForwardAgent = true;
        User = "averyan";
        HostName = "mole";
        HostKeyAlias = "serv2.asc.rssi.ru";
        Port = 3124;
      };

      "git.asc.rssi.ru" = {
        HostName = "mole";
        HostKeyAlias = "git.asc.rssi.ru";
        Port = 3123;
      };

      "circles.averyan.ru" = {
        ForwardAgent = true;
        User = "ubuntu";
        HostName = "195.209.218.189";
      };

      whale = {
        header = "Host whale whale.averyan.ru";
        HostName = "whale.averyan.ru";
        User = "alex";
        IdentitiesOnly = "yes";
        IdentityFile = "~/.ssh/id_ed25519";
      };
    };
  };
}
