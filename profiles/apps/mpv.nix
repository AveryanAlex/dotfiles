{ pkgs, ... }:
{
  hm = {
    programs.mpv = {
      enable = true;
      package = pkgs.mpv;
      config = {
        profile = "high-quality";
        ytdl-format = "bestvideo+bestaudio";
      };
      profiles = {
        high-quality = {
          hwdec = "vaapi";
          ao = "pipewire";
          vo = "dmabuf-wayland";
          # video-sync = "display-resample";
          # interpolation = true;
          # tscale = "oversample";
        };
      };
    };
  };
}
