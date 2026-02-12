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

  hm.programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
        headers = {
          CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
        };
      };
      exa = {
        url = "https://mcp.exa.ai/mcp?exaApiKey={env:EXA_API_KEY}";
      };
    };
  };
}
