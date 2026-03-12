{ pkgs, ... }:
let
  tmux-auto = pkgs.writeShellScriptBin "tmux-auto" ''
    ENTRYPOINT="''${1:-shell}"
    BASE="main"

    if ${pkgs.tmux}/bin/tmux new-session -d -s "$BASE" -c "$PWD" 2>/dev/null; then
      exec ${pkgs.tmux}/bin/tmux attach-session -t "=$BASE"
    fi

    GROUPED="''${BASE}-''${ENTRYPOINT}-$$-$(date +%s)"
    cleanup() { ${pkgs.tmux}/bin/tmux kill-session -t "=$GROUPED" 2>/dev/null; }
    trap cleanup EXIT
    ${pkgs.tmux}/bin/tmux new-session -d -t "=$BASE" -s "$GROUPED" -c "$PWD"
    ${pkgs.tmux}/bin/tmux new-window -t "=$GROUPED": -c "$PWD"
    ${pkgs.tmux}/bin/tmux attach-session -t "=$GROUPED"
  '';
in
{
  hm.home.packages = [ tmux-auto ];
}
