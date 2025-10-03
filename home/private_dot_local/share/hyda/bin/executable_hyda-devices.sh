#!/usr/bin/env bash

usage() {
  cat <<'EOF'

Hyda-Devices — Daemon To Detect Connect|Disconnected Devices

Usage: run the script directly and it will remain in the background

EOF
}

trim_name() {
  basename "$1" \
    | sed 's/_/ /g' \
    | sed 's/\bbattery\b//g' \
    | sed 's/  */ /g' \
    | sed 's/^ //;s/ $//' \
    | awk '{print $1, $2}'
}

notify_event() {
  local status="$1"
  local raw="$2"
  local name=$(trim_name "$raw")

  notify-send -e "🔌 Device $status" "<b>$name</b>" -a "HYDA" -r 9993 -h string:synchronous:connection -t 3000
}

main() {
  case "$1" in
    *added*)
      notify_event "Connected" "$1"
      ;;
    *removed*)
      notify_event "Disconnected" "$1"
      ;;
    *) 
      echo "unhandled: $1"
      ;; 
  esac
}

if [[ $# -gt 0 ]]; then
  usage
  exit 0
fi

upower --monitor 2>/dev/null | grep --line-buffered -E "device (added|removed):" | { while read -r line; do main "$line"; done }
