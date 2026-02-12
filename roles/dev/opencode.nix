{ pkgs, ... }:
{
  hm.programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      model = "synthetic/hf:moonshotai/Kimi-K2.5";
      enabled_providers = [ "synthetic" ];
      provider.synthetic.options.baseURL = "https://code.fob.wtf/syn/openai/v1";
      plugin = [ "opencode-wakatime" ];
      permission = {
        bash = "ask";
      };
    };
  };

  hm.home.packages = with pkgs; [
    mcp-nixos
  ];
}
