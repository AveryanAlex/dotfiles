{
  config,
  inputs,
  secrets,
  ...
}:
let
  commonSieve = ''
    require ["fileinto"];

    if header :contains ["Chat-Version"] [""] {
      fileinto "DeltaChat";
      stop;
    }
  '';
  certDir = config.security.acme.certs."averyan.ru".directory;
in
{
  systemd.tmpfiles.rules = [
    "d /persist/mail/dkim 755 221 221 - -"
    "d /persist/mail/sieve 770 5000 5000 - -"
    "d /persist/mail/vmail 6760 5000 5000 - -"
    "d /persist/mail/dovecot 755 0 0 - -"
    "d /persist/mail/postfix 755 0 0 - -"
    "d /persist/mail/redis-rspamd 700 997 997 - -"
    "d /persist/mail/rspamd 700 225 225 - -"
    "d /persist/mail/spool 1777 0 0 - -"
  ];

  networking.nat.forwardPorts =
    let
      mkRule = port: {
        destination = "192.168.12.36:${toString port}";
        sourcePort = port;
        proto = "tcp";
        loopbackIPs = [ "95.165.105.90" ];
      };
    in
    [
      (mkRule 25)
      (mkRule 465)
      (mkRule 993)
    ];

  age.secrets.mail-alex = {
    file = "${secrets}/mail/alex.age";
    path = "/run/mail-passwords/alex";
    symlink = false;
  };
  age.secrets.mail-sonya8128 = {
    file = "${secrets}/mail/sonya8128.age";
    path = "/run/mail-passwords/sonya8128";
    symlink = false;
  };
  age.secrets.mail-cofob = {
    file = "${secrets}/mail/cofob.age";
    path = "/run/mail-passwords/cofob";
    symlink = false;
  };

  systemd.services."container@mailserver".serviceConfig.MemoryMax = "2G";

  containers.mailserver = {
    autoStart = true;
    ephemeral = true;

    privateNetwork = true;
    hostBridge = "vms";
    localAddress = "192.168.12.36/24";

    bindMounts = {
      "/var/dkim/" = {
        hostPath = "/persist/mail/dkim";
        isReadOnly = false;
      };
      "/var/sieve/" = {
        hostPath = "/persist/mail/sieve";
        isReadOnly = false;
      };
      "/var/vmail/" = {
        hostPath = "/persist/mail/vmail";
        isReadOnly = false;
      };
      "/var/lib/dovecot/" = {
        hostPath = "/persist/mail/dovecot";
        isReadOnly = false;
      };
      "/var/lib/postfix/" = {
        hostPath = "/persist/mail/postfix";
        isReadOnly = false;
      };
      "/var/lib/redis-rspamd/" = {
        hostPath = "/persist/mail/redis-rspamd";
        isReadOnly = false;
      };
      "/var/lib/rspamd/" = {
        hostPath = "/persist/mail/rspamd";
        isReadOnly = false;
      };
      "/var/spool/mail/" = {
        hostPath = "/persist/mail/spool";
        isReadOnly = false;
      };
      "/run/mail-passwords/" = {
        hostPath = "/run/mail-passwords";
        isReadOnly = true;
      };
      "${certDir}/" = {
        hostPath = certDir;
        isReadOnly = true;
      };
    };

    config =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        imports = [
          inputs.mailserver.nixosModules.mailserver
        ];

        system.stateVersion = "24.05";

        networking = {
          defaultGateway = {
            address = "192.168.12.1";
            interface = "eth0";
          };
          firewall.enable = false;
          useHostResolvConf = false;
          nameservers = [
            "9.9.9.9"
            "8.8.8.8"
            "1.1.1.1"
            "77.88.8.8"
          ];
        };
        services.resolved.enable = true;

        # Work around pam_lastlog2 breakage that kills machinectl shell sessions.
        security.pam.services.login.updateWtmp = lib.mkForce false;

        services.dovecot2.sieve.extensions = [ "fileinto" ];

        mailserver = {
          stateVersion = 4;
          enable = true;
          fqdn = "whale.averyan.ru";
          domains = [ "averyan.ru" ];

          indexDir = "/var/lib/dovecot/indices";
          fullTextSearch = {
            enable = true;
            autoIndex = true;
            # indexAttachments = true;
          };

          storage = {
            owner = "vmail";
            group = "vmail";
            directoryLayout = "fs";
          };

          x509 = {
            certificateFile = certDir + "/fullchain.pem";
            privateKeyFile = certDir + "/key.pem";
          };

          dkim.defaults.keyLength = 2048;

          mailboxes = {
            Trash = {
              auto = "create";
              specialUse = "Trash";
            };
            Archive = {
              auto = "create";
              specialUse = "Archive";
            };
            Junk = {
              auto = "subscribe";
              specialUse = "Junk";
            };
            Drafts = {
              auto = "subscribe";
              specialUse = "Drafts";
            };
            Sent = {
              auto = "subscribe";
              specialUse = "Sent";
            };
          };

          accounts = {
            "alex@averyan.ru" = {
              hashedPasswordFile = "/run/mail-passwords/alex";
              sieveScript = commonSieve;
            };
            "sonya8128@averyan.ru" = {
              hashedPasswordFile = "/run/mail-passwords/sonya8128";
              sieveScript = commonSieve;
            };
            "cofob@averyan.ru" = {
              hashedPasswordFile = "/run/mail-passwords/cofob";
              sieveScript = commonSieve;
            };
          };
        };

        services.rspamd.extraConfig = ''
          actions {
            reject = null;
            add_header = 6;
            greylist = null;
          }
        '';
      };
  };
}
