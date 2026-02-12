{
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
