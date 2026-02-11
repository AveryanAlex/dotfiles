{
  inputs,
  config,
  ...
}:
let
  makeAveryanHost = proxyPass: {
    locations."/".proxyPass = proxyPass;
    locations."/".proxyWebsockets = true;
    useACMEHost = "averyan.ru";
  };
in
{
  imports = [
    inputs.self.nixosModules.roles.server
    inputs.self.nixosModules.hardware.aeza
    ./mounts.nix

    inputs.self.nixosModules.profiles.server.acme
    inputs.self.nixosModules.profiles.server.blog
    inputs.self.nixosModules.profiles.server.mail
    inputs.self.nixosModules.profiles.server.nginx
    inputs.self.nixosModules.profiles.server.ntfy-sh
    inputs.self.nixosModules.profiles.server.searx
    inputs.self.nixosModules.profiles.server.uptime-kuma

    inputs.self.nixosModules.profiles.persist-yggdrasil
    inputs.self.nixosModules.profiles.remote-builder-client

    ./tor.nix
  ];

  system.stateVersion = "22.05";

  age.secrets.wg-key.file = ../../secrets/wireguard/hawk.age;

  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = true;
    "net.ipv4.conf.default.forwarding" = true;

    "net.ipv6.conf.all.accept_ra" = 0;
    "net.ipv6.conf.default.accept_ra" = 0;

    "net.ipv6.conf.all.forwarding" = false;
    "net.ipv6.conf.default.forwarding" = false;
  };

  # TODO: refactor nginx

  services.nginx.virtualHosts = {
    "bw.averyan.ru" = makeAveryanHost "http://whale:8222";
    "dacha.averyan.ru" = makeAveryanHost "http://lizard:8123";
    "dav.averyan.ru" = makeAveryanHost "http://whale:5232";
    "git.averyan.ru" = makeAveryanHost "http://whale:3816";
    "grafana.averyan.ru" = makeAveryanHost "http://whale:3729";
    "home.averyan.ru" = makeAveryanHost "http://whale:8123";
    "hydra.averyan.ru" = makeAveryanHost "http://whale:2875";
    "ntfy.averyan.ru" = makeAveryanHost "http://127.0.0.1:8163";
    "olsearch.averyan.ru" = makeAveryanHost "http://whale:8739";
    "prism.averyan.ru" = makeAveryanHost "http://whale:2342";
    "search.averyan.ru" = makeAveryanHost "http://127.0.0.1:8278";
    "status.averyan.ru" = makeAveryanHost "http://127.0.0.1:3001";
    "yacy.averyan.ru" = makeAveryanHost "http://whale:8627";

    "ptero.averyan.ru" = makeAveryanHost "http://10.8.8.100:80";
    "whale-ptero.averyan.ru" = makeAveryanHost "http://10.8.8.100:443";
  };

  services.prometheus.exporters.wireguard.enable = true;

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
    defaultGateway = {
      address = "10.0.0.1";
      interface = "ens3";
    };
    # defaultGateway6 = {
    # address = "2a12:5940:d011::1";
    # interface = "ens3";
    # };

    nft-firewall = {
      extraFilterForwardRules = [
        "iifname wg0 oifname ens3 counter accept"
        "iifname ens3 oifname wg0 ct state { established, related } counter accept"
      ];
      extraNatPreroutingRules = [
        "ip daddr 185.112.83.99 tcp dport 25000-25100 dnat to 10.8.8.100"
        # "ip daddr 185.112.83.99 tcp dport 25565 dnat to 10.8.7.81"
        "ip daddr 185.112.83.99 tcp dport 2022 dnat to 10.8.8.100"
        "ip daddr 185.112.83.99 udp dport 25000-25100 dnat to 10.8.8.100"
      ];
      extraNatPostroutingRules = [ "oifname ens3 masquerade" ];
    };

    firewall = {
      allowedUDPPorts = [ 51820 ];
      interfaces."nebula.averyan".allowedTCPPorts = [ 9586 ]; # wg exporter
    };

    wireguard.interfaces = {
      wg0 = {
        ips = [ "10.8.7.1/24" ];
        listenPort = 51820;
        privateKeyFile = config.age.secrets.wg-key.path;
        peers = [
          {
            # Whale
            publicKey = "nt2xC/cl5opg4g5fUkvqKuUKORXLS/qGCikx7F0FBRQ=";
            allowedIPs = [ "10.8.8.0/24" ];
          }
          {
            # Vsevolod
            publicKey = "oKrAQE4sX4YjNf13qJz9IjprAH6YFhmt7CDUzXJVXl8=";
            allowedIPs = [ "10.8.7.240/32" ];
          }
          {
            # Kriger
            publicKey = "qxkQlt1Q9lHq+d48J9nkqTTC+Dzs2LHD+GycsSKDyyE=";
            allowedIPs = [ "10.8.7.241/32" ];
          }
          {
            # Ivanov
            publicKey = "bqkblOYoMi69RAIvJTy/zhovdUR+2O7JVaXoUqBXM2I=";
            allowedIPs = [ "10.8.7.242/32" ];
          }
          {
            # Tihonov
            publicKey = "mi4FUaRyD2yIbVtX1jC7cY7XXg6rUELcpAUyN+N7lU0=";
            allowedIPs = [ "10.8.7.243/32" ];
          }
          {
            # Despectdr
            publicKey = "/BRUH/MivTgVsGeTINUQ5pZDtX8nzrEv1vy+wNJE0Ws=";
            allowedIPs = [ "10.8.7.244/32" ];
          }
          {
            # Khrustaleva
            publicKey = "fZS0Loc8VTcARnokFwR4pgTiP+warZLa2IYHefiD8ho=";
            allowedIPs = [ "10.8.7.245/32" ];
          }
          {
            # Kazakova
            publicKey = "eoofp8UhHTo9SAgSDQmBKrqeF2me1goHIunWWE4Og1c=";
            allowedIPs = [ "10.8.7.246/32" ];
          }
          {
            # Karaseva
            publicKey = "dBmTwssDWdv+kQfnDl1sMdF7P6+E3szdJPud34tWq1k=";
            allowedIPs = [ "10.8.7.247/32" ];
          }
          {
            # Swan
            publicKey = "nQ5xDVQnHI9nPDXW79z7Ks5FHE0o0bqxA5ZKzh9dgEU=";
            allowedIPs = [ "10.8.7.248/32" ];
          }
          {
            # Poplik
            publicKey = "s4xNXZAq83WzDbIA9w4Ori9MrPuA8lsYKYRldfcrrHc=";
            allowedIPs = [ "10.8.7.249/32" ];
          }
          {
            # Alligator
            publicKey = "FtRuoT3cvVFGq4DGbBNMSEYDvhygFvMDAHWEnSUgfjo=";
            allowedIPs = [ "10.8.7.250/32" ];
          }
        ];
      };
    };

    # nebula-averyan.isLighthouse = true;

    interfaces = {
      ens3 = {
        ipv4 = {
          addresses = [
            {
              address = "185.112.83.99";
              prefixLength = 32;
            }
          ];
        };
        # ipv6 = {
        # addresses = [
        # {
        # address = "2a12:5940:d011::a";
        # prefixLength = 48;
        # }
        # ];
        # };
      };
    };
  };
}
