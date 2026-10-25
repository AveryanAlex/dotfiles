# Serial console support adapted from srvos. See ../LICENSES/srvos-MIT.txt.
{ lib, pkgs, ... }:
let
  consoles = [
    "ttyS0,115200"
  ]
  ++ lib.optional pkgs.stdenv.hostPlatform.isAarch "ttyAMA0,115200"
  ++ lib.optional pkgs.stdenv.hostPlatform.isRiscV64 "ttySIF0,115200"
  ++ [ "tty0" ];

  resize = pkgs.writeShellScriptBin "resize" ''
    export PATH=${pkgs.coreutils}/bin
    if [ ! -t 0 ]; then
      # not a interactive...
      exit 0
    fi
    TTY="$(tty)"
    if [[ "$TTY" != /dev/ttyS* ]] && [[ "$TTY" != /dev/ttyAMA* ]] && [[ "$TTY" != /dev/ttySIF* ]]; then
      # probably not a known serial console, we could make this check more
      # precise by using `setserial` but this would require some additional
      # dependency
      exit 0
    fi
    old=$(stty -g)
    stty raw -echo min 0 time 5

    printf '\0337\033[r\033[999;999H\033[6n\0338' > /dev/tty
    IFS='[;R' read -r _ rows cols _ < /dev/tty

    stty "$old"
    stty cols "$cols" rows "$rows"
  '';
in
{
  console = {
    earlySetup = true;
    font = "cyr-sun16";
    keyMap = "us";
  };

  boot.kernelParams = map (c: "console=${c}") consoles;
  environment.loginShellInit = "${resize}/bin/resize";
  environment.systemPackages = [ resize ];
  systemd.services."serial-getty@".environment.TERM = "xterm-256color";

  boot.loader.grub.extraConfig = ''
    serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1
    terminal_input --append serial
    terminal_output --append serial
  '';
}
