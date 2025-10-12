#!/usr/bin/env bash
# description: daemon for detecting connected/disconnected devices

trim_name() {
  basename "$1" \
    | sed 's/_/ /g; s/\bbattery\b//g; s/  */ /g; s/^ //; s/ $//' \
    | awk '{print $1, $2}'
}

notify_event() {
  local status="$1"
  local raw="$2"
  local name=$(trim_name "$raw")

  notify-send -e "🔌 Device $status" "<b>$name</b>" -a "HYDA" -r 9993 -t 3000
}

handle() {
  case "$1" in
    *added*)
      log_info "Device connected: $1"
      notify_event "Connected" "$1"
      ;;
    *removed*)
      log_info "Device disconnected: $1"
      notify_event "Disconnected" "$1"
      ;;
    *)
      log_warning "Unhandled event: $line"
      notify_event "Unknown Event: $1"
      ;;
  esac
}

main() {
  log_info "Hyda Devices Daemon Started"
  while read -r line; do handle "$line"; done < <(upower --monitor 2>/dev/null | grep --line-buffered -E "device (added|removed):")
}

if [[ $# -gt 0 ]]; then
  log_error "hyda devices daemon doesn't require argument, just run it as is"
  exit 1
else
  main
fi
