{ lib, pkgs, ... }:
{
  hm.home.packages = [ pkgs.git-xet ];

  hm.programs.git = {
    enable = true;
    lfs.enable = true;

    signing = {
      signByDefault = true;
      key = "3C23C7BD99452036";
      format = "openpgp";
    };

    ignores = [
      ".sisyphus"
      # ".agents"
      ".stignore"
      ".superpowers"
      ".wakatime-project"
      "**/.claude/settings.local.json"
    ];

    settings = {
      user.name = "AveryanAlex";
      user.email = "alex@averyan.ru";

      core.editor = "micro";
      init.defaultBranch = "main";
      lfs."customtransfer.xet" = {
        path = lib.getExe pkgs.git-xet;
        args = "transfer";
        concurrent = true;
      };
      pull.rebase = true;
      push.autoSetupRemote = true;
    };
  };

  hm.programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
}
