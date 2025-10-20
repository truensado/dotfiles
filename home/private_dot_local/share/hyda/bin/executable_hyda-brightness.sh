#!/usr/bin/env bash
# description: manage screen brightness

usage() {
  cat <<EOF

${bold}Hyda Brightness${reset} — cli tool for managing brightness

${bold}Usage:${reset}
  ${bold}increase${reset},  -i, --increase  ${info}increases brightness${reset} (${bold}default +10${reset})
  ${bold}decrease${reset},  -d, --decrease  ${info}decreases brightness${reset} (${bold}default -10${reset})
  ${bold}restore${reset},   -r, --restore   ${info}restore previous brightness${reset}
  ${bold}set${reset},       -s, --set       ${info}sets the brightness value directly${reset} (${bold}0-100${reset})

${bold}Example:${reset}
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
else
  log_error "no brightness backend detected"
  exit 1
fi

use_hypr() {
  local base=$(hyda_state_get "Brightness" "current")
  local prev=$(hyda_state_get "Brightness" "previous")

  [[ -z "$base" ]] && base=100
  [[ -z "$prev" ]] && prev=$base

  if [[ ! "$1" =~ ^[+-]?[0-9]+$ ]]; then
    log_error "brightness value must be an integer (e.g. 10, +10, -5)"
    return 1
  elif [[ "$1" =~ ^[+-] ]]; then
    new=$((base + $1))
  else
    new=$1
  fi

  ((new < 20)) && new=20
  ((new > 100)) && new=100

  if [[ "$new" -ne "$base" ]]; then
    hyda_state "Brightness" "previous" "$base"
    hyda_state "Brightness" "current" "$new"
  fi

  notify-send "Brightness" "<big>=====<b>$new%</b>=====</big>" -e -a "HYDA" -r 9992 -i "brightness-display-symbolic" -h string:synchronous:brightness -h int:value:$new
  hyprctl hyprsunset gamma "$new"
}

restore_hypr() {
  local value=$(hyda_state_get "Brightness" "previous" | tr -dc '0-9')
  [[ -z "$value" || ! "$value" =~ ^[0-9]+$ ]] && value=100
  use_hypr "$value"
}

case $1 in
  *increase | -i)
    shift
    if [[ "$backend" == "laptop" ]]; then
      brightnessctl "+${1:-10}"
    else
      use_hypr "+${1:-10}"
    fi
    ;;
  *decrease | -d)
    shift
    if [[ "$backend" == "laptop" ]]; then
      brightnessctl "-${1:-10}"
    else
      use_hypr "-${1:-10}"
    fi
    ;;
  *restore | -r)
    if [[ "$backend" == "laptop" ]]; then
      brightnessctl -r
    else
      restore_hypr
    fi
    ;;
  *set | -s)
    shift
    if [[ -z "$1" ]]; then
      echo
      log_error "missing brightness value"
      usage
      exit 1
    fi
    if [[ "$backend" == "laptop" ]]; then
      brightnessctl "$1"
    else
      use_hypr "$1"
    fi
    ;;
  *)
    usage
    ;;
esac
