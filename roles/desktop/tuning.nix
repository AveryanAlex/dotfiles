{
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.dirty_bytes" = 256 * 1024 * 1024;
    "vm.dirty_background_bytes" = 128 * 1024 * 1024;
    "vm.min_free_kbytes" = 100 * 1024;
  };
}
