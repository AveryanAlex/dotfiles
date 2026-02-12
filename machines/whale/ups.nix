{
  config,
  secrets,
  ...
}:
{
  age.secrets.upsmon-pass.file = "${secrets}/intpass/upsmon-pass.age";

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

  services.prometheus.exporters.nut = {
    enable = true;
  };
}
