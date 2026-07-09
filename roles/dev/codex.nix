{
  inputs,
  pkgs,
  ...
}:
let
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  hm.programs.codex = {
    enable = true;
    # package = llmAgents.codex;
    # enableMcpIntegration = true;
    #     settings = {
    #       # Grants unrestricted system access: AI can read/write any file and execute
    #       # network-enabled commands. Highly risky -- remove this setting if you're
    #       # new to Codex.
    #       sandbox_mode = "danger-full-access";
    #
    #       model = "gpt-5.5";
    #       model_provider = "omniroute";
    #       model_reasoning_effort = "high";
    #       # openai_base_url = "https://omniroute.neutrino.su/api/v1";
    #
    #       model_providers.omniroute = {
    #         name = "OmniRoute";
    #         base_url = "https://omniroute.neutrino.su/api/v1";
    #         env_key = "OMNIROUTE_API_KEY";
    #         wire_api = "responses";
    #       };
    #     };
  };
}
