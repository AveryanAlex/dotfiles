{ lib, ... }:
{
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "vscode-extension-ms-vscode-cpptools"
      "vscode-extension-github-copilot"
      "vscode-extension-github-copilot-chat"
      "vscode"
      "gh-copilot"
      "corefonts"
      "hplip"
      "obsidian"
      "mdk-sdk"
      "cursor"
      "antigravity"
      "code"
      "claude-code"
    ];
}
