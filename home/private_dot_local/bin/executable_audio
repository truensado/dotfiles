#!/usr/bin/env bash

set -euo pipefail

# 🚫 Sinks to ignore
IGNORED=(
  "alsa_output.pci-0000_00_1f.3.iec958-stereo"
  "alsa_output.pci-0000_01_00.1.hdmi-stereo"
)

# Get array of filtered sinks
mapfile -t sinks < <(
  pactl list short sinks | awk '{print $2}' | grep -vFf <(printf "%s\n" "${IGNORED[@]}")
)

# Exit if no valid sinks found
[[ ${#sinks[@]} -eq 0 ]] && {
  echo "❌ No valid sinks to cycle through." >&2
  exit 1
}

# Get current default sink
current_sink=$(pactl info | awk -F': ' '/Default Sink/ {print $2}')

# Find current sink index
current_index=-1
for i in "${!sinks[@]}"; do
  if [[ "${sinks[$i]}" == "$current_sink" ]]; then
    current_index=$i
    break
  fi
done

# Compute next sink (wrap around)
next_index=$(( (current_index + 1) % ${#sinks[@]} ))
next_sink="${sinks[$next_index]}"

# Apply new default sink
pactl set-default-sink "$next_sink"

# Move all streams to new sink
pactl list short sink-inputs | while read -r line; do
  input_id=$(awk '{print $1}' <<< "$line")
  pactl move-sink-input "$input_id" "$next_sink"
done

echo "🔄 Audio output switched to: $next_sink"
