{
  hm.programs.git = {
    enable = true;
    lfs.enable = true;

    signing = {
      signByDefault = true;
      key = "3C23C7BD99452036";
    };

    settings = {
      user.name = "AveryanAlex";
      user.email = "alex@averyan.ru";

      core.editor = "micro";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  hm.programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
