{
  lib,
  pkgs,
  config,
  ...
}:
let
  nbminer = pkgs.buildFHSEnv {
    name = "nbminer";
    targetPkgs =
      pkgs:
      (with pkgs; [
        udev
        ocl-icd
        rocmPackages.clr.icd
        rocmPackages.clr
      ]);
    runScript = "${
      pkgs.fetchzip {
        url = "https://dl.nbminer.com/NBMiner_42.3_Linux.tgz";
        sha256 = "2VGWWIKQbD1qkrat063fgo6ZiuRwTi8LU4YzyBWh1CA=";
      }
    }/nbminer";
  };
  teamredminer = pkgs.buildFHSEnv {
    name = "teamredminer";
    targetPkgs =
      pkgs:
      (with pkgs; [
        udev
        ocl-icd
        rocmPackages.clr.icd
        rocmPackages.clr
      ]);
    runScript = "${
      pkgs.fetchzip {
        url = "https://github.com/todxx/teamredminer/releases/download/v0.10.14/teamredminer-v0.10.14-linux.tgz";
        sha256 = "AVRhJ9H6GtIsrqln/9qJOPWjQjBBBCwe7r+aYfbQwOc=";
      }
    }/teamredminer";
  };
  srbminer = pkgs.buildFHSEnv {
    name = "srbminer";
    targetPkgs =
      pkgs:
      (with pkgs; [
        udev
        ocl-icd
        rocmPackages.clr.icd
        rocmPackages.clr
        wget
      ]);
    runScript = "${
      pkgs.fetchzip {
        url = "https://github.com/doktor83/SRBMiner-Multi/releases/download/2.3.2/SRBMiner-Multi-2-3-2-Linux.tar.xz";
        sha256 = "USYOskiwzLhOxQV4UAy5sseL0KOzZmpFCGL1vaTe1/M=";
      }
    }/SRBMiner-MULTI";
  };
  srbArgs = "--algorithm dynex --disable-cpu --pool stratum+tcp://dnx.mineradnow.space:18000 --mallob-endpoint https://gomallob.mineradnow.space/ml --wallet Xwn38pD2orDM7e1YSvwtyx6Jm7cebb9nKhnaneoist2QYyLqmUUTQJcTDgnM4X3qjsZrgfgojbnGEZRVepMAQYce28bdcprRp --password ${config.networking.hostName}";
  # srbArgs = ''--algorithm dynex\;sha256dt --pool stratum+tcp://dnx.mineradnow.space:18000\;stratum+tcp://sha256dt.mine.zergpool.com:3341 --wallet Xwn38pD2orDM7e1YSvwtyx6Jm7cebb9nKhnaneoist2QYyLqmUUTQJcTDgnM4X3qjsZrgfgojbnGEZRVepMAQYce28bdcprRp\;bitcoincash:qq6qj3tg52w50meq8syp33yaqdqqlv5cvqptjlej74 --password x\;c=BCH,ID=${config.networking.hostName} --cpu-threads -1\;-1'';

  # gpuArgs = "-a firopow -o stratum+tcp://firopow.mine.zergpool.com:3001 -u \"bitcoincash:qq6qj3tg52w50meq8syp33yaqdqqlv5cvqptjlej74\" -p \"c=BCH,ID=${config.networking.hostName}\"";
  gpuArgs = "-a kawpow -o stratum+ssl://kawpow.auto.nicehash.com:443 -u NHbV22CpSTtujLKfhXrnpSHT6mxFSB8m3wSi.${config.networking.hostName} -p x";
in
{
  environment.systemPackages = [
    nbminer
    teamredminer
    srbminer
  ];

  # boot.kernelParams = ["hugepagesz=1GB" "hugepages=3"];

  systemd.services.nbminer = {
    script = "${nbminer}/bin/nbminer ${gpuArgs}";
    after = [ "network.target" ];
    serviceConfig = {
      DynamicUser = true;
      SupplementaryGroups = [ "video" ];
      User = "nbminer";
    };
  };

  systemd.services.teamredminer = {
    script = "${teamredminer}/bin/teamredminer ${gpuArgs}";
    after = [ "network.target" ];
    serviceConfig = {
      DynamicUser = true;
      SupplementaryGroups = [ "video" ];
      User = "teamredminer";
    };
  };

  systemd.services.srbminer = {
    script = "${srbminer}/bin/srbminer ${srbArgs}";
    after = [ "network.target" ];
    serviceConfig = {
      DynamicUser = true;
      SupplementaryGroups = [ "video" ];
      User = "srbminer";
    };
  };

  systemd.services.gpu-mining-mode = {
    requiredBy = [
      "nbminer.service"
      "teamredminer.service"
      "srbminer.service"
    ];
    partOf = [
      "nbminer.service"
      "teamredminer.service"
      "srbminer.service"
    ];
    script = ''
      echo "manual" > /sys/class/drm/card0/device/power_dpm_force_performance_level
      echo "150000000" > /sys/class/drm/card0/device/hwmon/hwmon4/power1_cap
      echo "s 1 1250" > /sys/class/drm/card0/device/pp_od_clk_voltage
      echo "vo -175" > /sys/class/drm/card0/device/pp_od_clk_voltage
      echo "m 1 1055" > /sys/class/drm/card0/device/pp_od_clk_voltage
      echo "c" > /sys/class/drm/card0/device/pp_od_clk_voltage
    '';
    postStop = ''
      echo 255000000 > /sys/class/drm/card0/device/hwmon/hwmon4/power1_cap
    '';
    serviceConfig = {
      RemainAfterExit = true;
    };
  };
}
