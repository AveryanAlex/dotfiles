{
  lib,
  config,
  ...
}:
let
  allDevices = [
    "hamster"
    "alligator"
    "whale"
  ];
  commonFolder = name: {
    label = name;
    id = lib.strings.toLower name;
    path = "${config.services.syncthing.dataDir}/${name}";
    ignorePerms = false;
    devices = allDevices;
  };
in
{
  services.syncthing = {
    enable = true;

    user = "alex";
    group = "users";

    dataDir = lib.mkDefault "/home/alex";
    configDir = "/home/alex/.config/syncthing";

    openDefaultPorts = true;

    settings = {
      devices = {
        alligator = {
          addresses = [
            "tcp://10.57.1.40:22000"
          ];
          id = "XYYXB6U-Y24PGXJ-UEDYSHQ-HKYELXG-UF6I4S4-EKB3GB3-KU6DEUH-5JDCOAN";
        };
        whale = {
          addresses = [
            "tcp://whale.averyan.ru:22000"
          ];
          id = "CWES2IK-GJ5F2CI-4SXANKJ-5WOZKF7-5LBDF4U-2J7JSAJ-S3SSVN7-K5E3DAY";
        };
        hamster = {
          addresses = [
            "tcp://10.57.1.41:22000"
          ];
          id = "KF5NLPI-Z57MSPV-XZZXORA-QYVY5VR-GF2FHPW-EX3IUYS-MD5Z2S4-BMC6PAV";
        };
      };
      folders = {
        "projects" = commonFolder "projects";
      };
    };
  };

  persist.state.homeDirs = [ ".config/syncthing" ];
}
