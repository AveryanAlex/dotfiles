{
  persist = {
    state = {
      homeDirs = [
        ".ssh"
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
