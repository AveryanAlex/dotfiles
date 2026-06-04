{ lib, pkgs, ... }:
{
  hm.home.packages = [ pkgs.onefetch ];

  hm.programs.zsh.initContent = lib.mkAfter ''
    _onefetch_on_git_project_enter() {
      [[ -o interactive ]] || return

      local current_git_root previous_git_root
      current_git_root="$(${pkgs.git}/bin/git -C "$PWD" rev-parse --show-toplevel 2>/dev/null)" || return

      if [[ -n "''${OLDPWD:-}" ]]; then
        previous_git_root="$(${pkgs.git}/bin/git -C "$OLDPWD" rev-parse --show-toplevel 2>/dev/null)" || true
      fi

      if [[ "$current_git_root" != "$previous_git_root" ]]; then
        ${pkgs.onefetch}/bin/onefetch
      fi
    }

    chpwd_functions+=(_onefetch_on_git_project_enter)
  '';
}
