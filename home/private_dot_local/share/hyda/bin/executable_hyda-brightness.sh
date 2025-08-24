#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"
source "$scrDir/hyda-state.sh"

use_backlight=false
use_hyprsunset=false
use_swayosd=false

if [ -n "$(ls -A /sys/class/backlight >/dev/null 2>&1)" ]; then
  use_backlight=true
elif command -v hyprsunset >/dev/null 2>&1 && pgrep -x hyprsunset >/dev/null; then
  use_hyprsunset=true
fi

if command -v swayosd-client >/dev/null 2>&1 && pgrep -x swayosd-server >/dev/null; then
  use_swayosd=true
fi

usage() {
  cat <<'EOF'

Hyda-Brightness — Control Brightness

Usage:
 increase         -i | i  ->  Increase Brightness
 decrease         -d | d  ->  Decrease Brightness
EOF
}

use_hyprsunset() {
  local base new header="Brightness"
  
  if ! base=$(awk '/\[Brightness\]/{getline; print $0}' $state_file 2>/dev/null) || [[ -z "$base" ]]; then
    base=100
  fi

  if [[ ! "$1" =~ ^[+-][0-9]+$ ]]; then
    echo "Usage: use_hyprsunset [+|-]<number>"
    return 1
  fi

  new=$((base + $1))
  ((new < 0 )) && new=0
  ((new > 100)) && new=100

  set_state_lock "$header" "$new"
  notify-send "$header" "<big>=====<b>$new%</b>=====</big>" -e -a "HYDA" -r 9992 -i "brightness-display-symbolic" -h string:synchronous:brightness -h int:value:$new
  hyprctl hyprsunset gamma "$new"
}

case $1 in
  increase | i | -i)
    if $use_backlight; then
      if $use_swayosd; then
        swayosd-client --brightness +5
      else
        brightnessctl +5
      fi
    elif $use_hyprsunset; then
      use_hyprsunset +5
    else
      echo -e "${ERROR}ERROR${RESET}: No backlight method found"
    fi
    ;;
  decrease | d | -d)
    if $use_backlight; then
      if $use_swayosd; then
        swayosd-client --brightness -5
      else
        brightnessctl -5
      fi
    elif $use_hyprsunset; then
      use_hyprsunset -5
    else
      echo -e "${ERROR}ERROR${RESET}: No backlight method found"
    fi
    ;;
  *)
    usage
    ;;
esac      

