{pkgs, ...}: {
  services.opensnitch = {
    enable = true;
    settings = {
      Firewall = "nftables";
      DefaultDuration = "15m";
      DefaultAction = "allow";
      ProcMonitorMethod = "ebpf";
    };
  };

  hm = {
    # services.opensnitch-ui.enable = true;
    home.packages = [pkgs.opensnitch-ui];
    home.file.".config/opensnitch/settings.conf".text = ''
      [global]
      default_action=1
      default_duration=6
      default_ignore_rules=false
      default_ignore_temporary_rules=0
      default_popup_advanced=false
      default_popup_advanced_dstip=false
      default_popup_advanced_dstport=false
      default_popup_advanced_uid=false
      default_popup_position=0
      default_target=0
      default_timeout=0
      disable_popups=true
      screen_scale_factor=1
      screen_scale_factor_auto=true
      server_max_message_length=4MiB
      theme=
      theme_density_scale=0

      [notifications]
      enabled=true
      type=0
    '';
  };
}
