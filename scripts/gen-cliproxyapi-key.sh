#!/usr/bin/env bash
set -euo pipefail

surname="${1:-}"

if [[ -z "$surname" ]]; then
  echo "Usage: $0 <surname>" >&2
  exit 1
fi

random_len=12
prefix_len=3
suffix_len=6
alphabet='0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'

random=""

while ((${#random} < random_len)); do
  byte="$(od -An -N1 -tu1 /dev/urandom | tr -d ' ')"

  # Avoid modulo bias: 62 * 4 = 248, so reject 248..255
  if ((byte < 248)); then
    idx=$((byte % ${#alphabet}))
    random+="${alphabet:idx:1}"
  fi
done

prefix="${surname:0:prefix_len}"

while ((${#prefix} < prefix_len)); do
  prefix="${prefix}-"
done

if ((${#surname} >= prefix_len + suffix_len)); then
  suffix="${surname: -suffix_len}"
else
  suffix="${surname:prefix_len}"
  while ((${#suffix} < suffix_len)); do
    suffix="-${suffix}"
  done
fi

echo "${prefix}-${random}-${suffix}"
