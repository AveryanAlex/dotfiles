{ config, ... }:
{
  age.secrets.upsmon-pass.file = ../../secrets/intpass/upsmon-pass.age;

  power.ups = {
    enable = true;
    ups.exegate = {
      description = "ExeGate SpecialPro Smart LLB-2000";
      driver = "nutdrv_qx"; # "richcomm_usb";
      port = "auto";
      directives = [
        "vendorid = 0925"
        "productid = 1234"
        "pollinterval = 1"
        "pollfreq = 5"
      ];
    };
    users.upsmon = {
      upsmon = "primary";
      passwordFile = config.age.secrets.upsmon-pass.path;
    };
    upsmon.monitor.exegate = {
      user = "upsmon";
    };
  };
  # environment.etc = {
  #   upsdConf = {
  #     text = "";
  #     target = "nut/upsd.conf";
  #     mode = "0440";
  #   };
  #   upsdUsers = {
  #     text = ''
  #       [upsmon]
  #         password = ups
  #         upsmon master
  #     '';
  #     target = "nut/upsd.users";
  #     mode = "0440";
  #   };
  # upsmonConf = {
  #   text = ''
  #     MINSUPPLIES 1
  #     SHUTDOWNCMD "shutdown -h 0"
  #     POLLFREQ 5
  #     POLLFREQALERT 5
  #     HOSTSYNC 15
  #     DEADTIME 15
  #     RBWARNTIME 43200
  #     NOCOMMWARNTIME 300
  #     FINALDELAY 5
  #     MONITOR exegate@localhost 1 upsmon ups master
  #   '';
  #   target = "nut/upsmon.conf";
  #   mode = "0444";
  # };
  # };

  services.prometheus.exporters.nut = {
    enable = true;
  };
}
