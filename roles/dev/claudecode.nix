{ pkgs, ... }:
let
  vibe = pkgs.writeShellScriptBin "vibe" ''
    exec ${pkgs.bubblewrap}/bin/bwrap \
      --ro-bind / / \
      --bind "$(pwd)" "$(pwd)" \
      --dev /dev \
      --proc /proc \
      --tmpfs /tmp \
      -- claude --dangerously-skip-permissions "$@"
  '';
in
{
  hm.programs.claude-code = {
    enable = true;
    memory.text = builtins.readFile ./opencode-rules.md;
    settings = {
      skipDangerousModePermissionPrompt = true;

      effortLevel = "high";

      attribution = {
        commit = "";
        pr = "";
      };
      includeCoAuthoredBy = false;
      git = {
        includeCoAuthor = false;
        includePRFooter = false;
      };

      enabledPlugins = {
        "claude-code-wakatime@wakatime" = true;
        "rust-analyzer-lsp@claude-plugins-official" = true;
        "beads@beads-marketplace" = true;
        "frontend-design@claude-plugins-official" = true;
        "typescript-lsp@claude-plugins-official" = true;
        "superpowers@claude-plugins-official" = true;
        "safety-net@cc-marketplace" = true;
      };
      permissions.additionalDirectories = [ "~/.cargo" ];
    };
  };

  hm.home.packages = [ vibe ];
}
