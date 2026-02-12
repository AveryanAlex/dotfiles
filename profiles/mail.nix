{
  config,
  pkgs,
  secrets,
  ...
}:
{
  age.secrets.account-mail = {
    file = "${secrets}/accounts/mail.age";
    owner = "alex";
    group = "users";
  };

  home-manager.users.alex = {
    accounts.email.accounts."alex@averyan.ru" = {
      address = "alex@averyan.ru";
      userName = "alex@averyan.ru";
      realName = "Alexander Averyanov";
      primary = true;

      passwordCommand = "cat ${config.age.secrets.account-mail.path}";

      imap = {
        host = "whale.averyan.ru";
        port = 993;
      };
      smtp = {
        host = "whale.averyan.ru";
        port = 465;
      };

      gpg = {
        key = "3C23C7BD99452036";
        signByDefault = true;
      };

      thunderbird.enable = true;
    };

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

    # home.packages = with pkgs; [
    #   deltachat-desktop
    # ];
  };

  persist.state.homeDirs = [ ".thunderbird" ]; # ".config/DeltaChat"
}
