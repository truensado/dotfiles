#!/usr/bin/env bash
set -euo pipefail

# Constants
PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
SCREENSHOT_DIR="$PICTURES_DIR/screenshots"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
FILENAME="$SCREENSHOT_DIR/${TIMESTAMP}.png"

# Ensure screenshot directory exists
mkdir -p "$SCREENSHOT_DIR"

# Kill existing slurp if hanging
pkill -x slurp 2>/dev/null || true

# Take screenshot with annotation and copy to clipboard
grim -g "$(slurp -o)" -t ppm - | \
  satty --filename - \
        --actions-on-enter save-to-clipboard \
        --save-after-copy \
        --early-exit \
        --copy-command wl-copy \
        --output-filename "$FILENAME"
