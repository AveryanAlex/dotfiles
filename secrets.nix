let
  alex = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDP6BYhOQG5swda8e3YRo4LqhdNNAQd3NwkQME193izZ";
  users = [ alex ];

  alligator = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE7y1Vw/aeF69RDccAB2BB1IATUvVEQ7sIgAO5fUZKyC";
  hamster = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBMxV923jWZlK1zghe1WKc05rh0he/A1gO/CPYVKI/PP";
  desktops = [
    alligator
    hamster
  ];

  ferret = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJCrSdgjm9hxyFMCVCW+SzgF7AThC+fZy8RBQoFqCWT2";
  family = [ ferret ];

  hawk = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGNROiWZEvzjR6TVoeVrVoUI2Vsx3wmJSb9QojvdLK0e";
  falcon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPo6ltlqcLgX/QsU06PnBMvwbs1OTxIuuouseVYbZL7S";
  whale = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICtyxNV8IPSMHudJrMbemcK82LosU9tdNDV2rhf0Z9ps";
  lizard = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEkmHS0r9G9Qgsponr/XayqOXB28eR+eUiYtBA+x5vTK";
  diamond = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKI3lWpGU0TE74z0STnC1WuUAUNlMYipvUChSaJ/k0pw";
  grizzly = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP7uVSBbSkY2Dyv38TWzljK8eXH/K4q9CukqY8Aly3/I";
  servers = [
    falcon
    whale
    lizard
    diamond
  ];

  systems = desktops ++ family ++ servers;
in
{
  "secrets/remote-builder-ssh-key.age".publicKeys = users ++ systems;

  "secrets/accounts/mail.age".publicKeys = users ++ desktops;
  "secrets/accounts/wakatime.age".publicKeys = users ++ desktops;
  "secrets/accounts/deluge.age".publicKeys = users ++ [ whale ];
  "secrets/accounts/radicale.age".publicKeys = users ++ desktops ++ [ whale ];

  "secrets/passwords/alex.age".publicKeys = users ++ systems;
  "secrets/passwords/olga.age".publicKeys = users ++ systems;

  "secrets/mail/alex.age".publicKeys = users ++ [
    hawk
    whale
  ];
  "secrets/mail/sonya8128.age".publicKeys = users ++ [
    hawk
    whale
  ];
  "secrets/mail/cofob.age".publicKeys = users ++ [
    hawk
    whale
  ];

  "secrets/creds/bvilove.age".publicKeys = users ++ [ whale ];
  "secrets/creds/gayradar.age".publicKeys = users ++ [ whale ];
  "secrets/creds/anoquebot.age".publicKeys = users ++ [ whale ];
  "secrets/creds/picsavbot.age".publicKeys = users ++ [ whale ];
  "secrets/creds/bvilove-beta.age".publicKeys = users ++ [ whale ];
  "secrets/creds/kluckva.age".publicKeys = users ++ [ whale ];
  "secrets/creds/infinitytgadminsbot-eye210.age".publicKeys = users ++ [ whale ];
  "secrets/creds/cloudflare.age".publicKeys = users ++ [
    hawk
    whale
    grizzly
  ];
  "secrets/creds/cpmbot.age".publicKeys = users ++ [ whale ];
  "secrets/creds/firesquare.age".publicKeys = users ++ [ whale ];
  "secrets/creds/ipfs-cluster.age".publicKeys = users ++ [ whale ];
  "secrets/creds/searx.age".publicKeys = users ++ [
    hawk
    whale
  ];
  "secrets/creds/matrix.age".publicKeys = users ++ [ whale ];
  "secrets/creds/matrix-sliding-sync.age".publicKeys = users ++ [ whale ];
  "secrets/creds/mautrix-telegram.age".publicKeys = users ++ [ whale ];
  "secrets/creds/matrix-appservice-discord.age".publicKeys = users ++ [ whale ];
  "secrets/creds/forgejo-runner-token.age".publicKeys = users ++ [ whale ];
  "secrets/creds/automm.age".publicKeys = users ++ [ grizzly ];
  "secrets/creds/aplusmuz-music-scraper.age".publicKeys = users ++ [ falcon ];
  "secrets/creds/jupyter.age".publicKeys = users ++ [ whale ];
  "secrets/creds/memexpert.age".publicKeys = users ++ [ whale ];
  "secrets/creds/gptoolsbot.age".publicKeys = users ++ [ whale ];
  "secrets/creds/bash-init.age".publicKeys = users ++ desktops ++ servers;
  "secrets/creds/podman.age".publicKeys = users ++ desktops ++ servers;

  "secrets/intpass/pterodactyl-panel.age".publicKeys = users ++ [ whale ];
  "secrets/intpass/pterodactyl-redis.age".publicKeys = users ++ [ whale ];
  "secrets/intpass/photoprism.age".publicKeys = users ++ [ whale ];
  "secrets/intpass/grizzly-influxdb-admin.age".publicKeys = users ++ [ grizzly ];
  "secrets/intpass/grizzly-influxdb-admin-token.age".publicKeys = users ++ [ grizzly ];
  "secrets/intpass/upsmon-pass.age".publicKeys = users ++ [ whale ];
  "secrets/intpass/smb-tank.age".publicKeys = users ++ desktops;
  "secrets/intpass/nextcloud-root.age".publicKeys = users ++ [ whale ];

  "secrets/wireguard/hawk.age".publicKeys = users ++ [
    hawk
    falcon
  ];
  "secrets/wireguard/whale.age".publicKeys = users ++ [ whale ];
  "secrets/wireguard/alligator.age".publicKeys = users ++ [ alligator ];
  "secrets/wireguard/pterodactyl.age".publicKeys = users ++ [ whale ];
  "secrets/wireguard/firesquare.age".publicKeys = users ++ [ whale ];
  "secrets/wireguard/whale-frsqr.age".publicKeys = users ++ [ whale ];

  "secrets/xray/falcon.age".publicKeys = users ++ [ falcon ];
  "secrets/xray/desktop.age".publicKeys = users ++ systems;

  "secrets/yggdrasil/alligator.age".publicKeys = users ++ [ alligator ];
  "secrets/yggdrasil/whale.age".publicKeys = users ++ [ whale ];
  "secrets/yggdrasil/hawk.age".publicKeys = users ++ [ hawk ];

  "secrets/nebula/ca-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/ca-key.age".publicKeys = users;
  "secrets/nebula/alligator-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/alligator-key.age".publicKeys = users ++ [ alligator ];
  "secrets/nebula/hamster-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/hamster-key.age".publicKeys = users ++ [ hamster ];
  "secrets/nebula/hawk-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/hawk-key.age".publicKeys = users ++ [ hawk ];
  "secrets/nebula/whale-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/whale-key.age".publicKeys = users ++ [ whale ];
  "secrets/nebula/lizard-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/lizard-key.age".publicKeys = users ++ [ lizard ];
  "secrets/nebula/diamond-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/diamond-key.age".publicKeys = users ++ [ diamond ];
  "secrets/nebula/falcon-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/falcon-key.age".publicKeys = users ++ [ falcon ];
  "secrets/nebula/grizzly-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/grizzly-key.age".publicKeys = users ++ [ grizzly ];
  "secrets/nebula/ferret-crt.age".publicKeys = users ++ systems;
  "secrets/nebula/ferret-key.age".publicKeys = users ++ [ ferret ];

  "secrets/nebula-frsqr/ca-crt.age".publicKeys = users ++ systems;
  "secrets/nebula-frsqr/whale-crt.age".publicKeys = users ++ systems;
  "secrets/nebula-frsqr/whale-key.age".publicKeys = users ++ [ whale ];
  "secrets/nebula-frsqr/hamster-crt.age".publicKeys = users ++ systems;
  "secrets/nebula-frsqr/hamster-key.age".publicKeys = users ++ [ hamster ];
  "secrets/nebula-frsqr/alligator-crt.age".publicKeys = users ++ systems;
  "secrets/nebula-frsqr/alligator-key.age".publicKeys = users ++ [ alligator ];

  "apps/cinemabot/bot.age".publicKeys = users ++ [ whale ];
  "apps/wakapi/wakapi.age".publicKeys = users ++ [ whale ];
}
