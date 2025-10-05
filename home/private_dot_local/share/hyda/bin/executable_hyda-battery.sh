#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"

if ! grep -q "Battery" /sys/class/power_supply/BAT*/type &> /dev/null; then
  echo -e "${bold}Error${reset}: ${error}no battery detected...${reset}${ierror}"
  exit 1
fi

command -v upower &>/dev/null || { echo -e "${bold}Error${reset}: ${error}no battery detected...${reset}${ierror}"; exit 1; }

usage() {
  cat <<EOF
---- Hyda Battery Notifier Daemon ----

  runs in the background and detects changes in battery percentage and state
EOF
}


get_perc() {
  if [[ "$cur_perc" -ge "$full_threshold" && "$cur_stat" != "Discharging" && "$cur_stat" != "Full" ]] && ((cur_perc - prev_perc >= gap)); then
    notify-send -a "HYDA Power" -t 5000 -r 5 -u "critical" -i "battery-full-charged-symbolic" "Battery Charged" "Battery is at $cur_perc%. You can unplug the charger"
    prev_perc=$cur_perc
  elif [[ "$cur_perc" -le "$critical_threshold" ]]; then
    count=$((timer > mnt ? timer : mnt))
    while [ $count -gt 0 ] && [[ $cur_stat == "Discharging" ]]; do
      for battery in /sys/class/power_supply/BAT*; do cur_stat=$(<"$battery/status"); done
      [[ $cur_stat != "Discharging" ]] && break
      notify-send -a "HYDA Power" -t 5000 -r 5 -u "critical" -i "battery-empty-symbolic" "Battery Critically Low" "$cur_perc% is critically low. Device will suspend in $((count / 60)):$((count % 60)) ."
      count=$((count - 1))
      sleep 1
    done
    [ $count -eq 0 ] && ex_action
  elif [[ "$cur_perc" -le "$low_threshold" ]] && [[ "$cur_stat" == "Discharging" ]] && ((prev_perc - cur_perc >= gap)); then
    rounded=$(printf "%1d" $(((cur_perc + 5) / 10 * 10)))
    notify-send -a "HYDA Power" -t 5000 -r 5 -u "critical" -i "battery-level-${rounded:-10}-symbolic" "Battery Low" "Battery is at $cur_perc%. Connect the charger."
    prev_perc=$cur_perc
  fi
}

get_stat() {
  [[ $cur_perc -ge $full_threshold ]] && [[ "$cur_stat" != "Discharging" ]] && cur_stat="Full"
  case "$cur_stat" in
    "Discharging")
      if [[ "$prev_stat" != "Discharging" ]] || [[ "$prev_stat" == "Full" ]]; then
        prev_stat=$cur_stat
        urgency=$([[ $cur_perc -le $low_threshold ]] && echo "critical" || echo "normal")
        rounded=$(printf "%1d" $(((cur_perc + 5) / 10 * 10)))
        notify-send -a "HYDA Power" -t 5000 -r 5 -u "${urgency:-normal}" -i "battery-level-${rounded:-10}-symbolic" "Charger Unplugged" "Battery is at $cur_perc%."
      fi
      get_perc
      ;;
    "Not"* | "Charging")
      if [[ "$prev_stat" == "Discharging" ]] || [[ "$prev_stat" == "Not"* ]]; then
        prev_stat=$cur_stat
        count=$((timer > mnt ? timer : mnt))
        urgency=$([[ "$cur_perc" -ge $full_threshold ]] && echo "critical" || echo "normal")
        rounded=$(printf "%1d" $(((cur_perc + 5) / 10 * 10)))
        notify-send -a "HYDA Power" -t 5000 -r 5 -u "${urgency:-normal}" -i "battery-level-${rounded:-100}-charging-symbolic" "Charger Plugged" "Battery is at $cur_perc%."
      fi
      get_perc
      ;;
    "Full")
      if [[ $cur_stat != "Discharging" ]]; then
        now=$(date +%s)
        if [[ "$prev_stat" == *"harging"* ]] || ((now - lt >= $((notify * 60)))); then
          notify-send -a "HYDA Power" -t 5000 -r 5 -u "critical" -i "battery-full-charging-symbolic" "Battery Full" "Please unplug your charger"
          prev_stat=$cur_stat
          lt=$now
        fi
      fi
      ;;
  esac
}

ex_action() {
  count=$((timer > mnt ? timer : mnt))
  nohup systemctl suspend &>/dev/null &
}

get_bat() {
  tot_perc=0 bat_amount=0
  for battery in /sys/class/power_supply/BAT*; do
    cur_stat=$(<"$battery/status")
    cur_perc=$(<"$battery/capacity")
    tot_perc=$((tot_perc + cur_perc))
    bat_amount=$((bat_amount + 1))
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
  critical_threshold=${BATTERY_CRITICAL_THRESHOLD:-5}
  low_threshold=${BATTERY_LOW_THRESHOLD:-15}
  full_threshold=${BATTERY_FULL_THRESHOLD:-100}
  timer=${BATTERY_NOTIFY_TIMER:-120}
  mnt=${BATTERY_MIN_TIMER:-60}
  notify=${BATTERY_NOTIFY_INTERVAL:-1140}
  gap=${BATTERY_GAP:-5}
  
  get_bat
  
  prev_perc=$cur_perc
  prev_stat=$cur_stat
  
  for dev in $(upower -e | grep battery_BAT); do
    dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',path='$dev'" 2>/dev/null | \
    while read -r battery_status_change; do
      get_change
    done
  done
}

[ $# -gt 0 ] && usage || main
