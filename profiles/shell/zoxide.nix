{
  hm.programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  hm.home.shellAliases.cd = "z";

  persist.state.homeDirs = [ ".local/share/zoxide" ];
}
