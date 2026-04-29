{
  persist = {
    state = {
      homeDirs = [
        {
          directory = ".ssh";
          mode = "u=rwx,g=,o=";
        }
        "Documents"
        "Downloads"
        "Music"
        "Notes"
        "Share"
        "Pictures"
        "projects"
      ];
    };
    cache.homeDirs = [
      ".cache"
      ".cargo"
    ];
  };
}
