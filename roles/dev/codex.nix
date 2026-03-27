{ ... }:
{
  hm.programs.codex = {
    enable = true;
    enableMcpIntegration = true;
    settings = {
      # Disables all user confirmation prompts for actions. Extremely dangerous --
      # remove this setting if you're new to Codex.
      # approval_policy = "never";

      # Grants unrestricted system access: AI can read/write any file and execute
      # network-enabled commands. Highly risky -- remove this setting if you're
      # new to Codex.
      sandbox_mode = "danger-full-access";

      model = "gpt-5.4"; # Or gpt-5, you can also use any of the models that we support.
      model_reasoning_effort = "high";

      openai_base_url = "https://litellm.averyan.ru";
    };
  };
}
