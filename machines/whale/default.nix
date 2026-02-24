{
  inputs,
  config,
  secrets,
  ...
}:
let
  physWan = "enx2a26a0060857";
  wan = "wan0";
  physLan = "enx2a26a0060856";
  lan = "lan0";

  makeHost = proxyPass: {
    locations."/".proxyPass = proxyPass;
    locations."/".proxyWebsockets = true;
  };

  makeAveryanHost = proxyPass: makeHost proxyPass // { useACMEHost = "averyan.ru"; };
in
{
  imports = [
    ../../roles/server.nix

    ../../profiles/server/qbit.nix
    # inputs.self.nixosModules.profiles.server.cpmbot
    ../../profiles/server/gayradar.nix
    ../../profiles/server/anoquebot.nix
    ../../profiles/server/picsav.nix
    ../../profiles/server/acme.nix
    # inputs.self.nixosModules.profiles.server.blog
    # inputs.self.nixosModules.profiles.server.bvilove
    # inputs.self.nixosModules.profiles.server.gitea
    ../../profiles/server/hass.nix
    # inputs.self.nixosModules.profiles.server.hydra
    ../../profiles/server/kluckva.nix
    # inputs.self.nixosModules.profiles.server.mqtt
    ../../profiles/server/mysql.nix
    ../../profiles/server/nginx.nix
    ../../profiles/server/ntfy-sh.nix
    ../../profiles/server/pgsql.nix
    ../../profiles/server/radicale.nix
    ../../profiles/server/forgejo.nix
    ../../profiles/server/searx.nix
    ../../profiles/server/vaultwarden.nix
    ../../profiles/server/matomo.nix
    ../../profiles/server/qdrant.nix
    # inputs.self.nixosModules.profiles.server.meilisearch
    ../../profiles/server/memexpert.nix
    ../../profiles/server/gptoolsbot.nix
    # inputs.self.nixosModules.profiles.server.avtor24bot
    # inputs.self.nixosModules.profiles.server.aibox

    ../../profiles/libvirt.nix
    ../../profiles/persist-yggdrasil.nix
    ../../profiles/remote-builder-host.nix
    ../../profiles/sync.nix

    ./hardware.nix
    ./mounts.nix

    # ./firesquare.nix
    ./hass.nix
    # ./monitoring.nix
    # ./photoprism.nix
    ./pterodactyl.nix
    ./tanksrv.nix
    # ./yacy.nix
    # ./tor.nix
    ./i2p.nix
    ../../apps/lidarr
    ../../apps/slskd
    ../../apps/navidrome
    ../../apps/prowlarr
    # ./ups.nix
    # ./ipfs.nix
    ./mail.nix
    ./matrix.nix
    # ./cosmovert.nix
    ./webtlo.nix
    ./dns.nix
    ./borgserve.nix
    ./printing.nix
    ./docker.nix
    ./hao-woodpecker.nix
    ./xray.nix

    # ../../apps/cinemabot
    ../../apps/wakapi
    # ../../apps/s2sbot
    ../../apps/reelsgen
    ../../apps/nextcloud
    ../../apps/newsrelay
    # ../../apps/litellm
    # ../../apps/mtproto
  ];

  networking.tproxy.output.enable = true;

  # networking.tproxy.forward.interfaces = [lan];

  virtualisation.libvirtd.enable = true;
  users.users.alex.extraGroups = [ "libvirtd" ];

  system.stateVersion = "22.05";

  # RAM
  hardware.ksm.enable = true;
  persist.tmpfsSize = "16G";

  services.syncthing.dataDir = "/home/alex/tank/hot/sync";

  # Monitoring
  services.prometheus.exporters.node.enabledCollectors = [ "zoneinfo" ];

  # systemd.services.tempalarm = {
  #   description = "Temperature Alarm";
  #   wantedBy = ["multi-user.target"];
  #   script = ''
  #     while :
  #     do
  #       if [ "$(${pkgs.hddtemp}/bin/hddtemp /dev/sdb 2>/dev/null | grep -oP '[0-9]+°C' | grep -oP '[0-9]+')" -gt "45" ]; then
  #         delay=100
  #         ${pkgs.beep}/bin/beep -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay
  #         ${pkgs.beep}/bin/beep -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783
  #         ${pkgs.beep}/bin/beep -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay -n -f 493 -l $delay -n -l $delay -f 622 -l $delay -n -f 493 -l $delay -n -l $delay -f 739 -l $delay
  #         ${pkgs.beep}/bin/beep -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783 -l $delay -n -f 493 -l $delay -n -l $delay -f 659 -l $delay -n -f 493 -l $delay -n -l $delay -f 783
  #         for i in 1 2 3 4; do
  #             ${pkgs.beep}/bin/beep -f 493 -l $delay -n -l $delay -f 987 -l $delay -n -f 493 -l $delay -n -l $delay -f 880 -l $delay -n -f 493 -l $delay -n -l $delay -f 830 -l $delay -n -f 493 -l $delay -n -l $delay -f 880 -l $delay -n -f 493 -l $delay -n -l $delay -f 830 -l $delay -n -f 493 -l $delay -n -f 739 -l $delay -n -f 493 -l $delay -n -f 830 -l $delay -n -f 493 -l $delay -n -f 659 -l $delay -n -f 493 -l $delay -n -f 739 -l $delay -n -f 492 -l $delay -n -f 622 -l $delay -n -f 493 -l $delay -n -f 659 -l $delay -n -f 493 -l $delay -n -f 622 -l $delay -n -f 493 -l $delay -n -f 659 -l $delay -n -f 493 -l $delay -n -f 622 -l $delay -n -f 493 -l $delay -n -f 659 -l $delay -n -f 493 -l $delay -n -f 622 -l $delay
  #         done
  #       else
  #         sleep 60
  #       fi
  #     done
  #   '';
  # };

  # enable hardware beeper
  boot.kernelModules = [ "pcspkr" ];

  # NETWORKING

  # Enable forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv4.conf.default.forwarding" = true;
    "net.ipv6.conf.all.forwarding" = true;
    "net.ipv6.conf.default.forwarding" = true;
  };

  services.nginx.virtualHosts = {
    "bw.averyan.ru" = makeAveryanHost "http://whale:8222";
    "dacha.averyan.ru" = makeAveryanHost "http://lizard:8123";
    "dacha-frigate.averyan.ru" = makeAveryanHost "http://lizard:8971";
    "xartik-home.averyan.ru" = makeAveryanHost "http://[201:2e23:9bf2:f5c5:a9c8:7607:e359:2ea6]:8123";
    "xartik-immich.averyan.ru" = makeAveryanHost "http://[201:2e23:9bf2:f5c5:a9c8:7607:e359:2ea6]:2283";
    "dav.averyan.ru" = makeAveryanHost "http://[::1]:5232";
    "git.averyan.ru" = makeAveryanHost "http://whale:3816";
    "grafana.averyan.ru" = makeAveryanHost "http://whale:3729";
    "home.averyan.ru" = makeAveryanHost "http://10.90.18.2:8123" // {
      extraConfig = ''
        proxy_read_timeout 600;
        proxy_connect_timeout 60;
        proxy_send_timeout 600;
      '';
    };
    "hydra.averyan.ru" = makeAveryanHost "http://whale:2875";
    "ntfy.averyan.ru" = makeAveryanHost "http://127.0.0.1:8163";
    "olsearch.averyan.ru" = makeAveryanHost "http://whale:8739";
    "prism.averyan.ru" = makeAveryanHost "http://whale:2342";
    "search.averyan.ru" = makeAveryanHost "http://127.0.0.1:8278";
    "yacy.averyan.ru" = makeAveryanHost "http://whale:8627";
    "lab.averyan.ru" = makeAveryanHost "http://127.0.0.1:8874";
    "memexpert.net" = makeHost "http://127.0.0.1:3000" // {
      useACMEHost = "memexpert.net";
    };

    "git.neutrino.su" = makeHost "http://whale:3826" // {
      useACMEHost = "neutrino.su";
    };
    "bw.neutrino.su" = makeHost "http://whale:8222" // {
      useACMEHost = "neutrino.su";
    };

    "ptero.averyan.ru" = makeAveryanHost "http://192.168.12.50:80";
    "whale-ptero.averyan.ru" = makeAveryanHost "http://192.168.12.50:443";
    "diamond-ptero.averyan.ru" = makeAveryanHost "http://diamond:443";
    "codefob.averyan.ru" = makeAveryanHost "https://code.fob.wtf" // {
      extraConfig = ''
        proxy_buffering off;
      '';
    };
  };

  networking.nebula-averyan.isLighthouse = true;

  systemd.network.networks = {
    "40-${wan}" = {
      # gateway = ["95.165.96.1"];
      name = "${wan}";
      # routes = [
      #   {
      #     routeConfig =
      #       Destination = "95.165.96.1";
      #       Source = "95.165.105.90";
      #     };
      #   }
      # ];
      networkConfig = {
        DHCP = "yes";
        LinkLocalAddressing = "no";
        IPv6AcceptRA = false;
      };
    };

    "40-${lan}" = {
      name = "${lan}";
      networkConfig = {
        IPv6AcceptRA = false;
        DHCPServer = true;
      };
      dhcpServerConfig = {
        PoolOffset = 100;
        PoolSize = 50;
        EmitDNS = true;
        DNS = "1.1.1.1";
      };
    };

    "40-vms" = {
      networkConfig = {
        IPv6AcceptRA = false;
        ConfigureWithoutCarrier = true;
        DHCPServer = true;
      };
      dhcpServerConfig = {
        PoolOffset = 100;
        PoolSize = 50;
        EmitDNS = true;
        DNS = "192.168.3.1";
      };
    };

    "40-yggbr" = {
      networkConfig = {
        IPv6AcceptRA = false;
        ConfigureWithoutCarrier = true;
      };
      linkConfig.RequiredForOnline = false;
    };

    "40-wgav" = {
      routes = [
        {
          Destination = "::/0";
          Type = "unreachable";
          Table = 700;
        }
      ];
      routingPolicyRules = [
        {
          FirewallMark = 700;
          Table = 700;
        }
        # {
        #   routingPolicyRuleConfig = {
        #     User = "alex";
        #     Table = 700;
        #   };
        # }
      ];
    };
    "40-wgavbr" = {
      networkConfig = {
        IPv6AcceptRA = false;
        ConfigureWithoutCarrier = true;
      };
      linkConfig.RequiredForOnline = false;
      routingPolicyRules = [
        {
          IncomingInterface = "wgavbr";
          Table = 700;
        }
      ];
    };
  };

  age.secrets.wg-key-averyan.file = "${secrets}/wireguard/whale.age";
  networking.wireguard.interfaces = {
    wgav = {
      allowedIPsAsRoutes = false;
      privateKeyFile = config.age.secrets.wg-key-averyan.path;
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

  services.yggdrasil.settings = {
    Peers = [
      "tcp://yggdrasil.community.garage.networks.deavmi.assigned.network:2000"
      "tcp://sin.yuetau.net:6642"
      "tcp://195.123.245.146:7743"
      "tls://37.205.14.171:993"
      "tls://fi1.servers.devices.cwinfo.net:61995"
      "tls://aurora.devices.waren.io:18836"
      "tls://fr2.servers.devices.cwinfo.net:23108"
      "tcp://51.15.204.214:12345"
      "tls://cloudberry.fr1.servers.devices.cwinfo.net:54232"
      "tcp://s2.i2pd.xyz:39565"
      "tcp://94.130.203.208:5999"
      "tcp://ygg.mkg20001.io:80"
      "tcp://phrl42.ydns.eu:8842"
      "tcp://gutsche.tech:8888"
      "tcp://ygg1.mk16.de:1337"
      "tcp://ygg2.mk16.de:1337"
      "tls://vpn.ltha.de:443"
      "tls://de-fsn-1.peer.v4.yggdrasil.chaz6.com:4444"
      "tcp://yggdrasil.su:62486"
      "tls://x-fra-0.sergeysedoy97.ru:65535"
      "tcp://193.107.20.230:7743"
      "tcp://ygg.yt:80"
      "tls://94.140.114.241:4708"
      "tls://94.103.82.150:8080"
      "tcp://vpn.itrus.su:7991"
      "tls://45.147.198.155:6010"
      "tls://23.137.249.65:443"
      "tls://23.137.251.45:5222"
      "tls://x-ams-0.sergeysedoy97.ru:65535"
      "tls://x-ams-1.sergeysedoy97.ru:65535"
      "tls://pl1.servers.devices.cwinfo.net:11129"
      "tcp://185.165.169.234:8880"
      "tcp://yggno.de:18226"
      "tls://x-mow-0.sergeysedoy97.ru:65535"
      "tls://x-mow-1.sergeysedoy97.ru:65535"
      "tls://x-mow-2.sergeysedoy97.ru:65535"
      "tls://x-mow-3.sergeysedoy97.ru:65535"
      "tls://x-mow-4.sergeysedoy97.ru:65535"
      "tcp://45.147.200.202:12402"
      "tcp://45.95.202.21:12403"
      "tcp://box.paulll.cc:13337"
      "tls://x-led-0.sergeysedoy97.ru:65535"
      "tls://avevad.com:1337"
      "tcp://srv.itrus.su:7991"
      "tcp://antebeot.ru:7890"
      "tls://x-ovb-0.sergeysedoy97.ru:65535"
      "tls://x-ovb-1.sergeysedoy97.ru:65535"
      "tcp://itcom.multed.com:7991"
      "tcp://ekb.itrus.su:7991"
      "tls://x-kzn-0.sergeysedoy97.ru:65535"
      "tcp://y.zbin.eu:7743"
      "tls://185.130.44.194:7040"
      "tcp://ygg.ace.ctrl-c.liu.se:9998"
      "tcp://zhoskiy.xyz:30111"
      "tls://x-sto-0.sergeysedoy97.ru:65535"
      "tcp://193.111.114.28:8080"
      "tcp://78.27.153.163:33165"
      "tcp://158.101.229.219:17002"
      "tls://ca1.servers.devices.cwinfo.net:58226"
      "tcp://kusoneko.moe:9002"
      "tcp://supergay.network:9002"
      "tls://108.175.10.127:61216"
      "tls://102.223.180.74:993"
      "tcp://lancis.iscute.moe:49273"
      "tcp://longseason.1200bps.xyz:13121"
      "tls://44.234.134.124:443"
      "tcp://ygg3.mk16.de:1337"
      "tls://ygg.mnpnk.com:443"
      "tcp://cowboy.supergay.network:9111"
      "tls://ygg.jjolly.dev:3443"
      "tls://167.160.89.98:7040"
      "tcp://zabugor.itrus.su:7991"
    ];
    NodeInfo.public = {
      internet = [
        "tls://ygg-msk-1.averyan.ru:8362"
        "tcp://ygg-msk-1.averyan.ru:8363"
      ];
    };
  };

  networking = {
    nat = {
      externalInterface = wan;
      internalInterfaces = [
        lan
        "vms"
      ];
    };

    firewall = {
      interfaces.${lan}.allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [
        67
        546
      ]; # DHCP

      extraForwardRules = ''
        iifname yggbr oifname ygg0 accept
        iifname ygg0 oifname yggbr accept
        iifname wgavbr oifname wgav accept
        iifname wgav oifname wgavbr accept
      '';
    };

    bridges = {
      ${lan}.interfaces = [ "${physLan}" ];
      ${wan}.interfaces = [ "${physWan}" ];
      vms.interfaces = [ ];
      yggbr.interfaces = [ ];
      wgavbr.interfaces = [ ];
    };

    interfaces = {
      "${lan}" = {
        ipv4 = {
          addresses = [
            {
              address = "192.168.3.1";
              prefixLength = 24;
            }
          ];
        };
      };
      vms = {
        ipv4 = {
          addresses = [
            {
              address = "192.168.12.1";
              prefixLength = 24;
            }
          ];
        };
      };
      yggbr.ipv6.addresses = [
        {
          address = "30a:5fad::1";
          prefixLength = 64;
        }
      ];
      wgavbr = {
        ipv4 = {
          addresses = [
            {
              address = "10.8.8.1";
              prefixLength = 24;
            }
          ];
          routes = [
            {
              address = "10.8.8.0";
              prefixLength = 24;
              options.table = "700";
            }
          ];
        };
      };
      wgav = {
        ipv4 = {
          addresses = [
            {
              address = "10.8.8.2";
              prefixLength = 32;
            }
          ];
          routes = [
            {
              address = "10.8.7.0";
              prefixLength = 24;
            }
            {
              address = "10.8.7.0";
              prefixLength = 24;
              options.table = "700";
            }
            {
              address = "0.0.0.0";
              prefixLength = 0;
              via = "10.8.7.1";
              options.table = "700";
            }
          ];
        };
      };
    };
  };
}
