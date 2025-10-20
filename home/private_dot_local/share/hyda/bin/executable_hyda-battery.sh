#!/usr/bin/env bash
# description: daemon battery notifer

do_notify() {
  local urgency="${1:-normal}"
  local icon="${2:-}"
  local title="${3:-}"
  local body="${4:-}"
  notify-send -e -a "HYDA Power" -t 5000 -r 5 -u "$urgency" -i "$icon" "$title" "$body"
}

do_crit() {
  local count=$timer
  while [ "$count" -gt 0 ] && [[ "$cur_stat" == "Discharging" ]]; do
    for battery in ${bat_path}/BAT*; do cur_stat=$(<"$battery/status"); done
    [[ "$cur_stat" != "Discharging" ]] && break
    do_notify "critical" "battery-empty-symbolic" "Battery Critically Low" "$cur_perc% is critically low. Device will suspend in $((count / 60)):$((count % 60)) ."
    ((count--))
    sleep 1
  done
  if [[ "$count" -eq 0 ]]; then
    nohup systemctl suspend &>/dev/null &
  fi
}

get_perc() {
  if [[ "$cur_perc" -ge "$full_threshold" && "$cur_stat" != "Discharging" && "$cur_stat" != "Full" ]] && ((cur_perc - prev_perc >= gap)); then
    do_notify "critical" "battery-full-charged-symbolic" "Battery Charged" "Battery is at $cur_perc%. You can unplug the charger"
    prev_perc=$cur_perc
  elif [[ "$cur_perc" -le "$critical_threshold" ]]; then
    do_crit
  elif [[ "$cur_perc" -le "$low_threshold" ]] && [[ "$cur_stat" == "Discharging" ]] && ((prev_perc - cur_perc >= gap)); then
    local rounded=$(printf "%1d" $(((cur_perc + 5) / 10 * 10)))
    do_notify "critical" "battery-level-${rounded:-10}-symbolic" "Battery Low" "Battery is at $cur_perc%. Connect the charger."
    prev_perc=$cur_perc
  fi
}

get_stat() {
  [[ $cur_perc -ge $full_threshold ]] && [[ "$cur_stat" != "Discharging" ]] && cur_stat="Full"
  case "$cur_stat" in
    "Discharging")
      if [[ "$prev_stat" != "Discharging" ]] || [[ "$prev_stat" == "Full" ]]; then
        prev_stat=$cur_stat
        local urgency=$([[ $cur_perc -le $low_threshold ]] && echo "critical" || echo "normal")
        local rounded=$(printf "%1d" $(((cur_perc + 5) / 10 * 10)))
        do_notify "${urgency}" "battery-level-${rounded:-10}-symbolic" "Charger Unplugged" "Battery is at $cur_perc%."
      fi
      get_perc
      ;;
    "Not"* | "Charging")
      if [[ "$prev_stat" == "Discharging" ]] || [[ "$prev_stat" == "Not"* ]]; then
        prev_stat=$cur_stat
        local urgency=$([[ "$cur_perc" -ge $full_threshold ]] && echo "critical" || echo "normal")
        local rounded=$(printf "%1d" $(((cur_perc + 5) / 10 * 10)))
        do_notify "${urgency:-normal}" "battery-level-${rounded:-100}-charging-symbolic" "Charger Plugged" "Battery is at $cur_perc%."
      fi
      get_perc
      ;;
    "Full")
      [[ $cur_stat == "Discharging" ]] && return
      local now=$(date +%s)
      if [[ "$prev_stat" == *"harging"* ]] || ((now - lt >= $((interval * 60)))); then
        do_notify "critical" "battery-full-charging-symbolic" "Battery Full" "Please unplug your charger"
        prev_stat=$cur_stat
        lt=$now
      fi
      ;;
  esac
}

get_bat() {
  tot_perc=0 bat_amount=0
  for battery in ${bat_path}/BAT*; do
    cur_stat=$(<"$battery/status")
    cur_perc=$(<"$battery/capacity")
    tot_perc=$((tot_perc + cur_perc))
    ((bat_amount++))
  done
  cur_perc=$((tot_perc / bat_amount))
}

get_change() {
  get_bat
  if [ "$cur_stat" != "$last_stat" ] || [ "$cur_perc" != "$last_perc" ]; then
    last_stat=$cur_stat
    last_perc=$cur_perc
    get_stat
    get_perc
  fi
}

main() {
  bat_path="/sys/class/power_supply"
  critical_threshold=${BATTERY_CRITICAL_THRESHOLD:-5}
  low_threshold=${BATTERY_LOW_THRESHOLD:-15}
  full_threshold=${BATTERY_FULL_THRESHOLD:-100}
  timer=${BATTERY_NOTIFY_TIMER:-120}
  interval=${BATTERY_NOTIFY_INTERVAL:-1140}
  gap=${BATTERY_GAP:-5}
  
  get_bat
  
  prev_perc=$cur_perc
  prev_stat=$cur_stat
  
  for device in $(upower -e | grep battery_BAT); do
    dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',path='$device'" 2>/dev/null | \
    while read -r battery_status_change; do
      get_change
    done
  done
}

if [ $# -gt 0 ]; then
  log_error "hyda battery daemon doesn't require arguments - just run it as is"
  exit 1
elif ! grep -q "Battery" /sys/class/power_supply/BAT*/type &> /dev/null; then
  log_error "no battery detected"
  exit 1
elif ! command -v upower &>/dev/null; then 
  log_error "upower not installed"
  exit 1
fi

main
