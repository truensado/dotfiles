#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"

deps=(grim slurp satty)

for dep in "${deps[@]}"; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    echo -e "${error}Error${reset}: Missing dependency ${bold}$dep"
    exit 1
  fi
done

SsDir="${XDG_PICTURES_DIR:-$HOME/Pictures}/screenshots"

mkdir -p "$SsDir"
  
pkill -x slurp

grim -g "$(slurp -o)" -t ppm - | \
  satty --filename - \
        --actions-on-enter save-to-clipboard \
        --save-after-copy \
        --early-exit \
        --copy-command wl-copy \
        --output-filename "$SsDir/screenshot-$(date +'%Y%m%d_%H-%M-%S').png"
