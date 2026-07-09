{
  config,
  inputs,
  lib,
  secrets,
  ...
}:
let
  bridge = "hermesbr";
  gateway = "192.168.32.1";
  nameservers = [
    "9.9.9.9"
    "8.8.8.8"
    "1.1.1.1"
    "77.88.8.8"
  ];

  users = [
    {
      username = "alex";
      address = "192.168.32.2";
      hostMounts = [
        {
          hostPath = "/home/alex/tank/hot/sync/projects";
          rawPath = "/hermes-raw/projects";
          mappedPath = "/hermes-mnt/projects";
          hostUid = 1000;
          hostGid = 100;
          containerUid = 999;
          containerGid = 999;
        }
      ];
    }
    # {
    #   username = "elina";
    #   address = "192.168.32.3";
    #   hostMounts = [ ];
    # }
  ];

  mkName = user: "hermes-${user.username}";
  mkEnvSecretName = user: "${mkName user}-env";
  mkPersistDir = user: "/persist/hermes/${user.username}";

  mkTmpfiles =
    user:
    let
      persistDir = mkPersistDir user;
    in
    [
      "d ${persistDir}/state 700 0 0 - -"
      "d ${persistDir}/containers 700 0 0 - -"
    ];

  mkSecret = user: {
    name = mkEnvSecretName user;
    value.file = "${secrets}/creds/${mkEnvSecretName user}.age";
  };

  mkServiceLimit = user: {
    name = "container@${mkName user}";
    value.serviceConfig.MemoryMax = "16G";
  };

  mkHostMountBind = mount: {
    name = "${mount.rawPath}/";
    value = {
      inherit (mount) hostPath;
      isReadOnly = false;
    };
  };

  mkIdmappedFileSystem = mount: {
    name = mount.mappedPath;
    value = {
      device = mount.rawPath;
      fsType = "none";
      options = [
        "bind"
        "X-mount.idmap=u:${toString mount.hostUid}:${toString mount.containerUid}:1 g:${toString mount.hostGid}:${toString mount.containerGid}:1"
      ];
    };
  };

  mkMappedPathTmpfile = mount: "d ${mount.mappedPath} 755 0 0 - -";

  mkContainer =
    user:
    let
      name = mkName user;
      persistDir = mkPersistDir user;
      envSecret = mkEnvSecretName user;
      envPath = "/run/hermes.env";
    in
    {
      inherit name;
      value = {
        autoStart = true;
        ephemeral = true;

        privateNetwork = true;
        hostBridge = bridge;

        extraFlags = [
          "--system-call-filter=@keyring"
          "--system-call-filter=bpf"
        ];

        bindMounts = {
          "/var/lib/hermes/" = {
            hostPath = "${persistDir}/state";
            isReadOnly = false;
          };
          "/var/lib/containers/" = {
            hostPath = "${persistDir}/containers";
            isReadOnly = false;
          };
          ${envPath} = {
            hostPath = config.age.secrets.${envSecret}.path;
            isReadOnly = true;
          };
        }
        // lib.listToAttrs (map mkHostMountBind user.hostMounts);

        config =
          {
            lib,
            pkgs,
            ...
          }:
          {
            imports = [
              inputs.hermes-agent.nixosModules.default
            ];

            system.stateVersion = "25.11";
            time.timeZone = "Europe/Moscow";

            environment.systemPackages = with pkgs; [
              curl
              micro
              wget
            ];

            networking = {
              # Configure eth0 inside the container so NixOS also installs the
              # declared defaultGateway. Top-level localAddress with hostBridge
              # is preconfigured by container-init before scripted networking runs.
              interfaces.eth0.ipv4.addresses = [
                {
                  inherit (user) address;
                  prefixLength = 24;
                }
              ];
              defaultGateway = {
                address = gateway;
                interface = "eth0";
              };
              firewall.enable = true;
              useHostResolvConf = false;
              inherit nameservers;
            };
            services.resolved.enable = true;

            # Work around pam_lastlog2 breakage that kills machinectl shell sessions.
            security.pam.services.login.updateWtmp = lib.mkForce false;

            virtualisation.docker.enable = false;
            virtualisation.oci-containers.backend = "podman";
            virtualisation.podman.enable = true;

            fileSystems = lib.listToAttrs (map mkIdmappedFileSystem user.hostMounts);

            systemd.tmpfiles.rules = [
              "d /hermes-mnt 755 0 0 - -"
              "d /hermes-raw 755 0 0 - -"
            ]
            ++ map mkMappedPathTmpfile user.hostMounts;

            systemd.services.hermes-agent.unitConfig.RequiresMountsFor = map (
              mount: mount.mappedPath
            ) user.hostMounts;

            services.hermes-agent = {
              enable = true;
              addToSystemPackages = true;

              # Expected env file content:
              #   OPENAI_API_KEY=...
              #   EXA_API_KEY=...
              #   CONTEXT7_API_KEY=...
              #   GROQ_API_KEY=...
              #   _HERMES_FORCE_OPENAI_API_KEY=... # optional: expose key to terminal tools/opencode
              #   TELEGRAM_BOT_TOKEN=...
              #   TELEGRAM_ALLOWED_USERS=...
              environmentFiles = [ envPath ];
              environment = {
                OPENAI_BASE_URL = "https://omniroute.neutrino.su/v1";
                TELEGRAM_HOME_CHANNEL = "1004106925";
                _HERMES_FORCE_OPENAI_BASE_URL = "https://omniroute.neutrino.su/v1";
                TZ = "Europe/Moscow";
              };
              extraDependencyGroups = [
                "messaging"
                "voice"
              ];

              settings = {
                model = {
                  provider = "openai-api";
                  default = "gpt-5.5";
                  base_url = "https://omniroute.neutrino.su/v1";
                  api_mode = "codex_responses";
                };
                web.backend = "exa";
                mcp_servers.context7 = {
                  enabled = true;
                  url = "https://mcp.context7.com/mcp";
                  headers.CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
                };
                approvals.mode = "off";
                toolsets = [ "all" ];
                terminal = {
                  backend = "local";
                  env_passthrough = [ "TZ" ];
                  timeout = 180;
                };
                stt = {
                  enabled = true;
                  provider = "groq";
                };
                display.platforms.telegram = {
                  tool_progress = "new";
                  cleanup_progress = true;
                };
              };

              container = {
                enable = true;
                backend = "podman";
                image = "docker.io/ubuntu:26.04";
                extraVolumes = [
                  "/hermes-mnt:/mnt:rw"
                ];
              };
            };
          };
      };
    };
in
{
  networking.tproxy.forward.${bridge} = { };
  networking = {
    bridges.${bridge}.interfaces = [ ];
    nat.internalInterfaces = [ bridge ];
    interfaces.${bridge}.ipv4.addresses = [
      {
        address = gateway;
        prefixLength = 24;
      }
    ];
  };
  systemd.network.networks."40-${bridge}".networkConfig = {
    IPv6AcceptRA = false;
    ConfigureWithoutCarrier = true;
  };

  systemd.tmpfiles.rules = lib.concatMap mkTmpfiles users;
  age.secrets = lib.listToAttrs (map mkSecret users);
  systemd.services = lib.listToAttrs (map mkServiceLimit users);
  containers = lib.listToAttrs (map mkContainer users);
}
