{ pkgs, ... }:
{
  hm.home.packages = [
    (pkgs.writeShellScriptBin "deployapp" ''
      APP=$1
      if [ "$APP" == "" ]; then
        echo App required
        exit 1
      fi
      MACHINE=$2
      if [ "$MACHINE" == "" ]; then
        MACHINE="whale"
      fi

      cd /home/alex/projects/averyanalex/dotfiles
      echo ===UPDATING FLAKE INPUT===
      nix flake update $APP
      echo ===REBUILDING HOST===
      ./deploy.sh $MACHINE
      cd -
    '')
  ];
}
