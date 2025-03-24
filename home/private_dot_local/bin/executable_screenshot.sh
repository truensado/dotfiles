#!/usr/bin/env bash

if [ ! -d "$XDG_PICTURES_DIR/screenshots" ]; then
  mkdir -p $XDG_PICTURES_DIR/screenshots
fi

pkill -x slurp || grim -g "$(slurp -o)" -t ppm - | satty --filename - --early-exit --copy-command wl-copy --output-filename $XDG_PICTURES_DIR/screenshots/$(date '+%Y%m%d-%H:%M:%S').png
