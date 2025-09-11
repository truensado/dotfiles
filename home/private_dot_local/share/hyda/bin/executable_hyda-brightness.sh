#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"
source "$scrDir/hyda-state.sh"

is_backlight=false
is_hyprsunset=false

if [ -n "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
  is_backlight=true
elif command -v hyprsunset >/dev/null 2>&1 && pgrep -x hyprsunset >/dev/null; then
  is_hyprsunset=true
fi

usage() {
  cat <<'EOF'

Hyda-Brightness — Control Brightness

Usage:
  increase [amount]   | i [amount]  | -i [amount]   ->  Increase Brightness (default: 5)
  decrease [amount]   | d [amount]  | -d [amount]   ->  Decrease Brightness (default: 5)
  set <value>         | s <value>   | -s <value>    ->  Set brightness directly (0–100)
  restore             | r           | -r            ->  Restore to previous brightness

Examples:
  ./hyda-brightness.sh increase 10
  ./hyda-brightness.sh set 80
  ./hyda-brightness.sh restore
EOF
}

use_hyprsunset() {
  local base new current previous
  local cHeader="Brightness"
  local pHeader="Previous Brightness"

  base=$(awk '/\[Brightness\]/{getline; print $0}' "$state_file" 2>/dev/null | tr -dc '0-9')
  previous=$(awk '/\[Previous Brightness\]/{getline; print $0}' "$state_file" 2>/dev/null | tr -dc '0-9')
  
  [[ -z "$base" ]] && base=100
  [[ -z "$previous" ]] && previous=$base
  
  if [[ ! "$1" =~ ^[+-]?[0-9]+$ ]]; then
    echo -e "${bold}ERROR${reset}: ${error}number must be an integer like 10 or 5...${reset}${ierror}"
    return 1
  fi
  
  new=$((base + $1))
  ((new > 100)) && new=100
  ((new < 0)) && new=0

  if [[ "$new" -ne "$base" ]]; then
    set_state_lock "$pHeader" "$base"
    set_state_lock "$cHeader" "$new"
  fi

  notify-send "$cHeader" "<big>=====<b>$new%</b>=====</big>" -e -a "HYDA" -r 9992 -i "brightness-display-symbolic" -h string:synchronous:brightness -h int:value:$new
  hyprctl hyprsunset gamma "$new"
}

restore_hyprsunset() {
  local value=$(awk '/\[Previous Brightness\]/{getline; print $0}' "$state_file" 2>/dev/null)

  if [[ ! "$value" =~ ^[0-9]+$ ]] || [[ -z "$value" ]]; then
    value=100
  fi

  use_hyprsunset "$value"
}

case $1 in
  increase | i | -i)
    if $is_backlight; then
      brightnessctl "+${2:-10}"
    elif $is_hyprsunset; then
      use_hyprsunset "+${2:-10}"
    else
      echo -e "${bold}ERROR${reset}: ${error}no backlight method found...${reset}${ierror}"
    fi
    ;;
  decrease | d | -d)
    if $is_backlight; then
      brightnessctl "-${2:-10}"
    elif $is_hyprsunset; then
      use_hyprsunset "-${2:-10}"
    else
      echo -e "${bold}ERROR${reset}: ${error}no backlight method found...${reset}${ierror}"
    fi
    ;;
  restore | r | -r)
    if $is_backlight; then
      brightnessctl -r
    elif $is_hyprsunset; then
      restore_hyprsunset
    else
      echo -e "${bold}ERROR${reset}: ${error}no backlight method found...${reset}${ierror}"
    fi
    ;;
  set | s | -s)
    if $is_backlight; then
      brightnessctl "${2:-10}"
    elif $is_hyprsunset; then
      use_hyprsunset "${2:-10}"
    else
      echo -e "${bold}ERROR${reset}: ${error}no backlight method found...${reset}${ierror}"
    fi
    ;;
  *)
    usage
    ;;
esac
