{
  systemd.services.ntfy-sh.serviceConfig.MemoryMax = "512M";

  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = "127.0.0.1:8163";
      base-url = "https://ntfy.averyan.ru";
    };
  };

  # persist.state.dirs = [
  #   {
  #     directory = "/var/lib/ntfy-sh";
  #     user = "ntfy-sh";
  #     group = "ntfy-sh";
  #     mode = "u=rwx,g=rx,o=rx";
  #   }
  # ];
}
