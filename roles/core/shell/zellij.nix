{ pkgs, ... }:
let
  zellijWebPort = 38082;
  zellijWebProxyPort = 8082;
in
{
  hm.programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      default_mode = "locked";
      default_shell = "zsh";
      session_serialization = false;
      serialization_interval = 60;
      scroll_buffer_size = 100000;
      pane_frames = false;
      on_force_close = "detach";
      show_startup_tips = false;
      web_server = true;
      web_server_ip = "127.0.0.1";
      web_server_port = zellijWebPort;
      web_sharing = "on";
    };
  };

  # hm.systemd.user.services.zellij-web = {
  #   Unit = {
  #     Description = "Zellij web server";
  #     After = [ "network-online.target" ];
  #     Wants = [ "network-online.target" ];
  #   };
  #   Service = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.zellij}/bin/zellij web";
  #     Restart = "on-failure";
  #     RestartSec = "10s";
  #   };
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };

  hm.systemd.user.services.zellij-web-http-proxy = {
    Unit = {
      Description = "Zellij web HTTP proxy";
      After = [
        "network-online.target"
        "zellij-web.service"
      ];
      Wants = [
        "network-online.target"
        "zellij-web.service"
      ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:${toString zellijWebProxyPort},bind=0.0.0.0,reuseaddr,fork TCP:127.0.0.1:${toString zellijWebPort}";
      Restart = "on-failure";
      RestartSec = "10s";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  networking.firewall.interfaces."nebula.averyan".allowedTCPPorts = [ zellijWebProxyPort ];
}
