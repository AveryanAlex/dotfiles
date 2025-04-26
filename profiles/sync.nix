{
  lib,
  config,
  ...
}: let
  allDevices = ["hamster" "alligator" "whale"];
  commonFolder = name: {
    label = name;
    id = lib.strings.toLower name;
    path = "${config.services.syncthing.dataDir}/${name}";
    ignorePerms = false;
    devices = allDevices;
  };
in {
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
            "tcp://192.168.3.60:22000"
            "tcp://10.57.1.40:22000"
          ];
          id = "XYYXB6U-Y24PGXJ-UEDYSHQ-HKYELXG-UF6I4S4-EKB3GB3-KU6DEUH-5JDCOAN";
        };
        whale = {
          addresses = [
            "tcp://whale.averyan.ru:22000"
          ];
          id = "Q3SH2WU-IZ2DW2W-PGYCBXF-TR4LOSK-Z4C3TBU-PDMVA77-AJ3K55U-OODJKAG";
        };
        hamster = {
          addresses = [
            "tcp://10.57.1.41:22000"
          ];
          id = "ZE5OQPP-KCHNC7V-NK62XZN-ZWU4K6V-FJONTJN-SDJMJ7Y-RZZR4AY-IDGD4QB";
        };
        swan.id = "W27UARY-LHBFRTY-HCGL557-NZ7POI5-2XW45NH-7DGKWWP-2D7V6ZS-4JM2VQE";
        pchel.id = "UCTK67O-NXE755G-GOOI32N-CJXY4NJ-OW7HWZ2-QGLZL2P-H5RE54F-WTUWKAX";
      };
      folders = {
        "Documents" = commonFolder "Documents";
        "projects" = commonFolder "projects";
        "Music" = commonFolder "Music"; # // {devices = allDevices ++ ["swan"];};
        "Notes" = commonFolder "Notes" // {devices = allDevices ++ lib.optional (config.networking.hostName == "whale") "swan";};
        "Pictures" = commonFolder "Pictures"; # // {devices = allDevices ++ ["swan"];};
        "Share/Pchela" =
          commonFolder "Share/Pchela"
          // {
            devices = allDevices ++ ["pchel"];
            id = "pchela";
          };
      };
    };
  };

  # systemd.services.syncthing.after = ["multi-user.target"];

  persist.state.homeDirs = [".config/syncthing"];
}
