{
  home-manager.users.olga = {
    programs.thunderbird = {
      enable = true;
      profiles.default = {
        isDefault = true;
        withExternalGnupg = true;
      };
      settings = {
        "privacy.donottrackheader.enabled" = true;
      };
    };
  };

  persist.state.homeDirs = [ ".thunderbird" ];
}
