{ pkgs, ... }:
let
  dockerImage = pkgs.dockerTools.pullImage {
    imageName = "yacy/yacy_search_server";
    finalImageTag = "latest";
    imageDigest = "sha256:78dc1fd08f6ff0c4b994733e631c26716cdc20795df209b11fe54a13c97bf3da";
    sha256 = "sha256-+KWkXBCfeodz3w1hSoy65+PFzFc5ejZKQPPR+wE4zR4=";
  };
in
{
  # systemd.tmpfiles.rules = [
  #   "d /hdd/yacy-ygg 755 107 113 - -"
  #   # "d /hdd/yacy-olymp 755 115 121 - -"
  #   # "d /hdd/yacy-freeworld 755 115 121 - -"
  # ];

  fileSystems."/var/lib/yacy-ygg" = {
    device = "UUID=bcfa404a-68de-4a25-9fb0-4e972c8f9423";
    fsType = "btrfs";
    options = [
      "autodefrag"
      "subvol=@yacy-ygg"
    ];
  };

  # virtualisation.oci-containers = {
  #   containers = {
  #     yacy-olymp = {
  #       image = "yacy/yacy_search_server";
  #       imageFile = dockerImage;
  #       volumes = [
  #         "/hdd/yacy-olymp/:/opt/yacy_search_server/DATA/"
  #       ];
  #       extraOptions = ["--network=host"];
  #     };
  #     yacy-freeworld = {
  #       image = "yacy/yacy_search_server";
  #       imageFile = dockerImage;
  #       volumes = [
  #         "/hdd/yacy-freeworld/:/opt/yacy_search_server/DATA/"
  #       ];
  #       extraOptions = ["--network=host"];
  #     };
  #   };
  # };

  # networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [8739 8627];

  systemd.services."container@yacy-ygg".serviceConfig = {
    # IOSchedulingPriority = 6;
    MemoryMax = "12G";
  };

  containers.yacy-ygg = {
    autoStart = true;
    ephemeral = true;

    privateNetwork = true;
    hostBridge = "yggbr";

    extraFlags = [
      "--system-call-filter=@keyring"
      "--system-call-filter=bpf"
    ];

    bindMounts = {
      "/var/lib/yacy/" = {
        hostPath = "/var/lib/yacy-ygg";
        isReadOnly = false;
      };
    };

    config =
      {
        config,
        pkgs,
        ...
      }:
      {
        system.stateVersion = "23.11";
        networking = {
          firewall.enable = false;
          interfaces.eth0.ipv6 = {
            addresses = [
              {
                address = "30a:5fad::e";
                prefixLength = 64;
              }
            ];
            routes = [
              {
                address = "200::";
                prefixLength = 7;
                via = "30a:5fad::1";
              }
            ];
          };
        };

        boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 1;

        virtualisation.oci-containers = {
          containers = {
            yacy-ygg = {
              image = "yacy/yacy_search_server";
              imageFile = dockerImage;
              volumes = [
                "/var/lib/yacy/:/opt/yacy_search_server/DATA/"
              ];
              extraOptions = [ "--network=host" ];
            };
          };
        };
      };
  };
}
