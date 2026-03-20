{
  config,
  pkgs,
  secrets,
  ...
}:
let
  kimakiVersion = "0.4.79";
  kimaki = pkgs.writeShellScriptBin "kimaki" ''
    exec ${pkgs.nodejs_latest}/bin/npx -y kimaki@${kimakiVersion} "$@"
  '';
in
{
  age.secrets.kimaki-bot-token = {
    file = "${secrets}/creds/kimaki.age";
    owner = "alex";
    group = "users";
  };

  hm.home.packages = [ kimaki ];

  hm.systemd.user.services.kimaki = {
    Unit = {
      Description = "Kimaki Discord bot for OpenCode";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      EnvironmentFile = config.age.secrets.kimaki-bot-token.path;
      ExecStart = "${kimaki}/bin/kimaki";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
