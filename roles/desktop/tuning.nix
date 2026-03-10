{ pkgs, ... }:
{
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.dirty_bytes" = 256 * 1024 * 1024;
    "vm.dirty_background_bytes" = 128 * 1024 * 1024;
    "vm.min_free_kbytes" = 100 * 1024;
    "vm.vfs_cache_pressure" = 50;
    "vm.dirty_writeback_centisecs" = 300;
    "vm.dirty_expire_centisecs" = 1500;
    "vm.compaction_proactiveness" = 0;
    "vm.page_lock_unfairness" = 1;
    "kernel.sched_autogroup_enabled" = 1;
    "net.core.default_qdisc" = "cake";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };

  boot.kernelModules = [ "sch_cake" ];

  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
    extraRules = [
      {
        name = "gcc";
        type = "BG_CPUIO";
      }
      {
        name = "cc1";
        type = "BG_CPUIO";
      }
      {
        name = "cc1plus";
        type = "BG_CPUIO";
      }
      {
        name = "c++";
        type = "BG_CPUIO";
      }
      {
        name = "as";
        type = "BG_CPUIO";
      }
      {
        name = "ld";
        type = "BG_CPUIO";
      }
      {
        name = "ld.lld";
        type = "BG_CPUIO";
      }
      {
        name = "lld";
        type = "BG_CPUIO";
      }
      {
        name = "rustc";
        type = "BG_CPUIO";
      }
      {
        name = "cargo";
        type = "BG_CPUIO";
      }
      {
        name = "make";
        type = "BG_CPUIO";
      }
      {
        name = "ninja";
        type = "BG_CPUIO";
      }
      {
        name = "cmake";
        type = "BG_CPUIO";
      }
      {
        name = "nix";
        type = "BG_CPUIO";
      }
    ];
  };

  services.scx = {
    enable = true;
    scheduler = "scx_bpfland";
  };

  environment.shellAliases.nbuild = "nice -n 19 ionice -c 3";
}
