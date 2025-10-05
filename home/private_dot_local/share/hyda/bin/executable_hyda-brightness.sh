#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"
source "$scrDir/hyda-state.sh"

usage() {
  cat <<'EOF'

Hyda-Brightness — Script Utility for Managing Brightness

Usage:
 --increase | increase  | -i    ->  increases brightness
 --decrease | decrease  | -d    ->  decreases brightness
 --restore  | restore   | -r    ->  restore previous brightness
 --set      | set       | -s    ->  sets the brightness value directly
Example:
  hydacli brightness increase 40
  hydacli brightness decrease 20
  hydacli brightness restore
  hydacli brightness set 90
EOF
}

if [ -n "$(ls -A /sys/class/backlight &>/dev/null)" ] && command -v brightnessctl &>/dev/null; then
  backend="laptop"
elif command -v hyprsunset &>/dev/null; then
  ! pgrep -x hyprsunset &>/dev/null && systemctl --user enable --now hyprsunset
  backend="desktop"
else
  echo -e "${bold}Error${reset}: no backend detected...${reset}${ierror}"
  exit 1
fi

use_hypr() {
  local base=$(awk '/\[Brightness\]/{getline; print $0}' "$state_file" 2>/dev/null | tr -dc '0-9')
  local previous=$(awk '/\[Previous Brightness\]/{getline; print $0}' "$state_file" 2>/dev/null | tr -dc '0-9')

  [[ -z "$base" ]] && base=100
  [[ -z "$previous" ]] && previous=$base

  if [[ ! "$1" =~ ^[+-]?[0-9]+$ ]]; then
    echo -e "${bold}Error${reset}: ${error}number must be an integer like 10 or 5...${reset}${ierror}"
    return 1
  else
    if [[ "$1" =~ ^[+-] ]]; then
      new=$((base + $1))
    else
      new=$1
    fi
  fi

  ((new < 20)) && new=20
  ((new > 100)) && new=100

  if [[ "$new" -ne "$base" ]]; then
    set_state_lock "Previous Brightness" "$base"
    set_state_lock "Brightness" "$new"
  fi

  notify-send "Brightness" "<big>=====<b>$new%</b>=====</big>" -e -a "HYDA" -r 9992 -i "brightness-display-symbolic" -h string:synchronous:brightness -h int:value:$new
  hyprctl hyprsunset gamma "$new"
}

restore_hypr() {
  local value=$(awk '/\[Previous Brightness\]/{getline; print $0}' "$state_file" 2>/dev/null)
  
  if [[ ! "$value" =~ ^[0-9]+$ ]] || [[ -z "$value" ]]; then
    value=100
  fi
  
  use_hypr "$value"
}

case $1 in
  *increase | -i)
    if [[ "$backend" == "laptop" ]]; then
      brightnessctl "+${2:-10}"
    elif [[ "$backend" == "desktop" ]]; then
      use_hypr "+${2:-10}"
    else
      echo -e "${bold}Error${reset}: ${error}no backlight method found...${reset}${ierror}"
    fi
    ;;
  *decrease | -d)
    if [[ "$backend" == "laptop" ]]; then
      brightnessctl "-${2:-10}"
    elif [[ "$backend" == "desktop" ]]; then
      use_hypr "-${2:-10}"
    else
      echo -e "${bold}Error${reset}: ${error}no backlight method found...${reset}${ierror}"
    fi
    ;;
  *restore | -r)
    if [[ "$backend" == "laptop" ]]; then
      brightnessctl -r
    elif [[ "$backend" == "desktop" ]]; then
      restore_hypr
    else
      echo -e "${bold}Error${reset}: ${error}no backlight method found...${reset}${ierror}"
    fi
    ;;
  *set | -s)
    if [[ "$backend" == "laptop" ]]; then
      brightnessctl "${2:-10}"
    elif [[ "$backend" == "desktop" ]]; then
      if [[ "$2" =~ ^[+-] ]]; then
        echo -e "${bold}Error${reset}: ${error}number must be an integer like 10 or 5...${reset}${ierror}"
        usage
        exit 1
      fi
      use_hypr "${2:-10}"
    else
      echo -e "${bold}Error${reset}: ${error}no backlight method found...${reset}${ierror}"
    fi
    ;;
  *)
    usage
    ;;
esac
