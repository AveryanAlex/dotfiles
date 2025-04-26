{pkgs, ...}: {
  home-manager.users.alex = {
    home.packages = with pkgs; [
      # mpc-cli # cli mpd client
      # mmtc # tui mpd client
      # cantata # qt mpd client
      # ario # gtk3 mpd client
      cava # music visualizer
      cassette # yandex music client
    ];

    services.mpd = {
      # enable = true;
      musicDirectory = "/home/alex/Music";
    };

    programs.ncmpcpp = {
      # enable = true;
    };

    dconf.settings."io/github/Rirusha/Cassette/application".application-state = "online";
  };

  persist.state.homeDirs = [".local/share/cassette"];
}
