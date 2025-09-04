#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"
source "$scrDir/hyda-state.sh"

use_backlight=false
use_hyprsunset=false
use_swayosd=false

if [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
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
  increase [amount]   | i [amount] | -i [amount]   ->  Increase Brightness (default: 5)
  decrease [amount]   | d [amount] | -d [amount]   ->  Decrease Brightness (default: 5)
  set <value>         ->  Set brightness directly (0–100)
  restore             ->  Restore to previous brightness

Examples:
  ./hyda-brightness.sh increase 10
  ./hyda-brightness.sh set 80
  ./hyda-brightness.sh restore
EOF
}

save_previous_brightness() {
  local current
  if current=$(awk '/\[Brightness\]/{getline; print $0}' "$state_file" 2>/dev/null); then
    set_state_lock "PreviousBrightness" "$current"
  fi
}

use_hyprsunset() {
  save_previous_brightness

  local delta=$1
  local base new header="Brightness"

  if ! base=$(awk '/\[Brightness\]/{getline; print $0}' "$state_file" 2>/dev/null) || [[ -z "$base" ]]; then
    base=100
  fi

  if [[ ! "$delta" =~ ^[+-]?[0-9]+$ ]]; then
    echo "Invalid delta: must be an integer like +10 or -5"
    return 1
  fi

  new=$((base + delta))
  ((new < 0 )) && new=0
  ((new > 100)) && new=100

  set_state_lock "$header" "$new"
  notify-send "$header" "<big>=====<b>$new%</b>=====</big>" -e -a "HYDA" -r 9992 -i "brightness-display-symbolic" -h string:synchronous:brightness -h int:value:$new
  hyprctl hyprsunset gamma "$new"
}

set_brightness() {
  save_previous_brightness

  local value=$1
  if [[ ! "$value" =~ ^[0-9]+$ ]] || ((value < 0 || value > 100)); then
    echo "Brightness must be a number between 0 and 100"
    return 1
  fi

  set_state_lock "Brightness" "$value"

  if $use_backlight; then
    if $use_swayosd; then
      swayosd-client --brightness "$value"
    else
      brightnessctl set "$value%"
    fi
  elif $use_hyprsunset; then
    notify-send "Brightness" "<big>=====<b>$value%</b>=====</big>" -e -a "HYDA" -r 9992 -i "brightness-display-symbolic" -h string:synchronous:brightness -h int:value:$value
    hyprctl hyprsunset gamma "$value"
  else
    echo -e "${ERROR}ERROR${RESET}: No backlight method found"
    return 1
  fi
}

restore_brightness() {
  local value
  if ! value=$(awk '/\[PreviousBrightness\]/{getline; print $0}' "$state_file" 2>/dev/null) || [[ -z "$value" ]]; then
    echo "No previous brightness state found."
    return 1
  fi
  set_brightness "$value"
}

# Default step value
step=5
[[ "$2" =~ ^[0-9]+$ ]] && step=$2

case $1 in
  increase | i | -i)
    if $use_backlight; then
      if $use_swayosd; then
        swayosd-client --brightness "+$step"
      else
        brightnessctl "+$step"
      fi
    elif $use_hyprsunset; then
      use_hyprsunset "+$step"
    else
      echo -e "${ERROR}ERROR${RESET}: No backlight method found"
    fi
    ;;
  decrease | d | -d)
    if $use_backlight; then
      if $use_swayosd; then
        swayosd-client --brightness "-$step"
      else
        brightnessctl "-$step"
      fi
    elif $use_hyprsunset; then
      use_hyprsunset "-$step"
    else
      echo -e "${ERROR}ERROR${RESET}: No backlight method found"
    fi
    ;;
  set)
    if [[ -z "$2" ]]; then
      echo "Usage: set <value>"
    else
      set_brightness "$2"
    fi
    ;;
  restore)
    restore_brightness
    ;;
  *)
    usage
    ;;
esac
