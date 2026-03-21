{ config, pkgs, ... }:
let
  kimakiVersion = "0.4.79";
  kimaki = pkgs.writeShellScriptBin "kimaki" ''
    exec ${pkgs.nodejs_latest}/bin/npx -y kimaki@${kimakiVersion} "$@"
  '';
in
{
  hm.home.packages = [ kimaki ];

  hm.systemd.user.services.kimaki = {
    Unit = {
      Description = "Kimaki Discord bot for OpenCode";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      WorkingDirectory = "%h/projects";
      ExecStart = "${pkgs.bash}/bin/bash -c 'source ${config.age.secrets.bash-init.path} && exec ${kimaki}/bin/kimaki'";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
