{ pkgs, lib, ... }:
{
  imports = [
    ./core
  ];

  systemd = {
    enableEmergencyMode = false;

    settings = {
      Manager.RebootWatchdogSec = "10m";
      Manager.RuntimeWatchdogSec = "30s";
    };

    sleep.settings.Sleep = {
      AllowSuspend = "no";
      AllowHibernation = "no";
    };
  };

  systemd.targets.network-online.wantedBy = [ "multi-user.target" ];
  systemd.network.wait-online.enable = true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  boot.kernel.sysctl = {
    # VM tuning for server throughput
    "vm.dirty_ratio" = 40;
    "vm.dirty_background_ratio" = 10;
    "vm.min_free_kbytes" = 131072;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.compaction_proactiveness" = 0;

    # Disable autogroup (useless for servers — no TTY sessions)
    "kernel.sched_autogroup_enabled" = 0;

    # Network optimization
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.somaxconn" = 8192;
    "net.core.netdev_max_backlog" = 16384;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_tw_reuse" = 1;

    # File descriptor limits
    "fs.file-max" = 2097152;
    "fs.inotify.max_user_watches" = 524288;
  };

  hm.services.gpg-agent.pinentry.package = pkgs.pinentry-curses;
}
