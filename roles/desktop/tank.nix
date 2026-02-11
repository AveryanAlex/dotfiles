{
  boot.supportedFilesystems = [ "nfs" ];

  systemd.mounts = [
    {
      type = "nfs";
      mountConfig = {
        Options = "rw,noatime";
      };
      what = "whale:/home/alex/tank";
      where = "/tank";
      after = [ "nebula@averyan.service" ];
      wants = [ "nebula@averyan.service" ];
    }
  ];

  systemd.automounts = [
    {
      wantedBy = [ "multi-user.target" ];
      automountConfig = {
        TimeoutIdleSec = "300";
      };
      where = "/tank";
    }
  ];

  # age.secrets.smb-tank.file = ../secrets/intpass/smb-tank.age;
  # boot.supportedFilesystems = ["cifs"];
  # # systemd.services.rpcbind.wants = ["systemd-tmpfiles-setup.service"];
  # # systemd.services.rpcbind.after = ["systemd-tmpfiles-setup.service"];

  # systemd.mounts = [
  #   {
  #     type = "smb3";
  #     mountConfig = {
  #       Options = "rw,credentials=${config.age.secrets.smb-tank.path},seal,resilienthandles,unix,uid=alex,gid=users";
  #     };
  #     what = "//10.57.1.10/tank";
  #     where = "/tank";
  #     after = ["nebula@averyan.service"];
  #     wants = ["nebula@averyan.service"];
  #   }
  # ];

  # systemd.automounts = [
  #   {
  #     wantedBy = ["multi-user.target"];
  #     automountConfig = {
  #       TimeoutIdleSec = "300";
  #     };
  #     where = "/tank";
  #   }
  # ];
}
