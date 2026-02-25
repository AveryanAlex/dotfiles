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
    settings = {
      skipDangerousModePermissionPrompt = true;
      enabledPlugins = {
        "claude-code-wakatime@wakatime" = true;
        "rust-analyzer-lsp@claude-plugins-official" = true;
      };
      permissions.additionalDirectories = [ "~/.cargo" ];
    };
  };

  hm.home.packages = [ vibe ];
}
