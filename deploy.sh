#!/bin/sh
MACHINE=$1
TYPE=$2
if [ "$TYPE" == "" ]; then
  TYPE="switch"
fi

nixos-rebuild "$TYPE" --flake ".#$MACHINE" --target-host $MACHINE --build-host $MACHINE --sudo --show-trace
