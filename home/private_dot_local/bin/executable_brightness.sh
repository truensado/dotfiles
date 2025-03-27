#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# 🔁 Map Hyprland name → ddcutil display number
declare -A MONITOR_MAP=(
  ["DP-1"]=1
  ["DP-2"]=2
)

# -------------------------
# 🔍 Detect focused monitor
focused_monitor=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
ddc_display="${MONITOR_MAP[$focused_monitor]:-}"

# -------------------------
# 🔦 Try brightnessctl first
has_brightnessctl() {
  command -v brightnessctl &>/dev/null
}

supports_brightnessctl() {
  brightnessctl -d "$focused_monitor" info &>/dev/null
}

adjust_brightnessctl() {
  local delta="$1"
  brightnessctl -d "$focused_monitor" set "$delta"
}

# -------------------------
# 💡 Fallback to ddcutil
get_ddc_brightness() {
  ddcutil getvcp 10 --display "$ddc_display" 2>/dev/null \
    | awk -F'current value = |,' '{print $2}'
}

set_ddc_brightness() {
  local value="$1"
  ddcutil setvcp 10 "$value" --display "$ddc_display"
}

clamp() {
  local val="$1"
  (( val < 0 )) && echo 0 && return
  (( val > 100 )) && echo 100 && return
  echo "$val"
}

adjust_ddcutil() {
  local delta="$1"
  local current new
  current=$(get_ddc_brightness)
  new=$((current + delta))
  new=$(clamp "$new")
  set_ddc_brightness "$new"
}

# -------------------------
# 🧠 Main logic
if [[ $# -ne 1 || ! "$1" =~ ^[+-]?[0-9]+$ ]]; then
  echo "Usage: $(basename "$0") [+N|-N|N]"
  echo "Examples: brightness.sh +10 | -5 | 75"
  exit 2
fi

if has_brightnessctl && supports_brightnessctl; then
  adjust_brightnessctl "$1"
elif [[ -n "$ddc_display" ]]; then
  if [[ "$1" =~ ^[+-] ]]; then
    adjust_ddcutil "${1}"
  else
    set_ddc_brightness "$(clamp "$1")"
  fi
else
  echo "❌ No valid method found for monitor '$focused_monitor'"
  exit 1
fi
