#!/usr/bin/env bash

bat_path="/sys/class/power_supply"

declare -A current_devices 
declare -A previous_devices

normalize_device_name() {
  echo "$1" | awk '{
    gsub(/[_-]/, " ")                    # underscores & dashes to space
    gsub(/battery/, "")                  # remove word "battery"
    gsub(/[0-9a-f]{2}(:[0-9a-f]{2})+/, "") # remove MAC-like hex
    gsub(/[0-9]+/, "")                   # remove numbers
    gsub(/^ +| +$/, "")                  # trim spaces
    print
  }'
}

notify_device_event() {
  local type="$1"
  local raw_name="$2"
  local display_name
  display_name=$(normalize_device_name "$raw_name")

  notify-send -e "🔌 Device $type" "<b>$display_name</b>" \
    -a "HYDA" -r 9993 -h string:synchronous:connection -t 3000
}

detect_changes() {
  for dev in "${!previous_devices[@]}"; do
    [[ -z "${current_devices[$dev]}" ]] && notify_device_event "Disconnected" "$dev"
  done

  for dev in "${!current_devices[@]}"; do
    [[ -z "${previous_devices[$dev]}" ]] && notify_device_event "Connected" "$dev"
  done
}

refresh_devices() {
  previous_devices=()
  for dev in "${!current_devices[@]}"; do
    previous_devices["$dev"]="${current_devices[$dev]}"
  done

  current_devices=()
  for dev in "$bat_path"/*; do
    name=$(basename "$dev")
    [[ $name == BAT* ]] && continue

    [[ -f "$dev/scope" ]] && grep -q "Device" "$dev/scope" && current_devices["$name"]="$name"
  done
}

while true; do
  refresh_devices
  detect_changes
  sleep 1
done
