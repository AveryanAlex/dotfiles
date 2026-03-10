#!/bin/sh
MACHINE=$1
TYPE=$2
if [ "$TYPE" == "" ]; then
  TYPE="switch"
fi

# Assumes passwordless sudo on the remote host for nixos-rebuild --sudo.
nixos-rebuild "$TYPE" --flake ".#$MACHINE" --target-host $MACHINE --build-host $MACHINE --sudo --show-trace
