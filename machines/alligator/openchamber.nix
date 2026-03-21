{
  config,
  pkgs,
  secrets,
  ...
}:
let
  openchamberVersion = "1.9.1";
  openchamber = pkgs.writeShellScriptBin "openchamber" ''
    export PATH=${pkgs.bash}/bin:${pkgs.nodejs_latest}/bin:$PATH
    exec ${pkgs.nodejs_latest}/bin/npx -y @openchamber/web@${openchamberVersion} "$@"
  '';
in
{
  age.secrets.openchamber-ui-password = {
    file = "${secrets}/creds/openchamber-ui-password.age";
    owner = "alex";
    group = "users";
  };

  hm.home.packages = [ openchamber ];

  hm.systemd.user.services.openchamber = {
    Unit = {
      Description = "OpenChamber web UI";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "10s";
      EnvironmentFile = config.age.secrets.openchamber-ui-password.path;
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'source ${config.age.secrets.bash-init.path} && exec ${openchamber}/bin/openchamber stop --port 8088'";
      ExecStart = "${pkgs.bash}/bin/bash -c 'source ${config.age.secrets.bash-init.path} && exec ${openchamber}/bin/openchamber --port 8088'";
      ExecStop = "${pkgs.bash}/bin/bash -c 'source ${config.age.secrets.bash-init.path} && exec ${openchamber}/bin/openchamber stop --port 8088'";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
