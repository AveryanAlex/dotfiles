{
  inputs,
  config,
  secrets,
  ...
}:
let
  firesquare-module = inputs.firesquare-servers.nixosModules.default;
in
{
  age.secrets.wg-key-firesquare.file = "${secrets}/wireguard/firesquare.age";
  networking.wireguard.interfaces = {
    wg-firesquare = {
      allowedIPsAsRoutes = false;
      privateKeyFile = config.age.secrets.wg-key-firesquare.path;
      peers = [
        {
          publicKey = "h+76esMcmPLakUN/1vDlvGGf2Ovmw/IDKKxFtqXCdm8=";
          allowedIPs = [ "0.0.0.0/0" ];
          endpoint = "vpn.averyan.ru:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  systemd.services.setup-firesquare-dirs = {
    script = ''
      mkdir -p /persist/firesquare/mysql
      chown 84:84 /persist/firesquare/mysql
      chmod 700 /persist/firesquare/mysql
    '';
    serviceConfig.RemainAfterExit = true;
  };

  systemd.services."container@firesquare" = {
    requires = [
      "wireguard-wg-firesquare.service"
      "wireguard-wg-firesquare.target"
      "setup-firesquare-dirs.service"
    ];
    after = [
      "wireguard-wg-firesquare.service"
      "wireguard-wg-firesquare.target"
      "setup-firesquare-dirs.service"
    ];
  };

  age.secrets.firesquare-passwords.file = "${secrets}/creds/firesquare.age";

  containers.firesquare = {
    autoStart = true;
    ephemeral = true;

    privateNetwork = true;
    interfaces = [ "wg-firesquare" ];

    bindMounts = {
      "/var/lib/mysql/" = {
        hostPath = "/persist/firesquare/mysql";
        isReadOnly = false;
      };
      "/run/passwords.env".hostPath = config.age.secrets.firesquare-passwords.path;
    };

    config = {
      imports = [ firesquare-module ];
      system.stateVersion = "22.11";

      networking = {
        interfaces.wg-firesquare.ipv4.addresses = [
          {
            address = "10.8.7.81";
            prefixLength = 32;
          }
        ];
        defaultGateway = {
          address = "10.8.7.1";
          interface = "wg-firesquare";
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
    };
  };
}
