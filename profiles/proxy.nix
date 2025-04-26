{
  services.privoxy = {
    enable = true;
    settings = {
      toggle = "0";
      enable-remote-toggle = "0";
      max-client-connections = "1024";
      forward-socks5 = [
        "api.github.com falcon:1080 ."
        "copilot-proxy.githubusercontent.com falcon:1080 ."
        ".githubcopilot.com falcon:1080 ."
        ".openai.com falcon:1080 ."
        ".generativelanguage.googleapis.com falcon:1080 ."
        ".anthropic.com falcon:1080 ."
        ".chatgpt.com falcon:1080 ."
        ".rutracker.org falcon:1080 ."
        ".rutracker.cc falcon:1080 ."
        ".play.google.com falcon:1080 ."
        ".youtube.com falcon:1080 ."
      ];
    };
  };
}
