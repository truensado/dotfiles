#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"

grep -q "Battery" /sys/class/power_supply/BAT*/type &> /dev/null || { echo -e "${bold}Error${reset}: ${error}no battery detected...${reset}${ierror}"; exit 0; }

usage() {
  cat <<EOF
---- Hyda Battery Notifier Daemon ----

  runs in the background and detects changes in battery percentage and state
EOF
}

do_perc() {
  if [[ "$batPerc" -ge "$unThresh" ]] && [[ "$batStat" != "Discharging" ]] && [[ "$batStat" != "Full" ]] && (((batPerc - lastPerc) >= interval)); then
    notify-send -a "HYDA Power" -t 5000 -r 5 -u "critical" -i "battery-full-charged-symbolic" "Battery Charged" "Battery is at $batPerc%. You can unplug the charger"
    lastPerc=$batPerc
  elif [[ "$batPerc" -le "$critThresh" ]]; then
    count=$((timer > mnt ? timer : mnt))
    while [ $count -gt 0 ] && [[ $batStat == "Discharging"* ]]; do
      for battery in /sys/class/power_supply/BAT*; do batStat=$(<"$battery/status"); done
      if [[ $batStat != "Discharging" ]]; then break; fi
      notify-send -a "HYDA Power" -t 5000 -r 5 -u "critical" -i "battery-empty-symbolic" "Battery Critically Low" "$batPerc% is critically low. Device will execute $exCrit in $((count / 60)):$((count % 60)) ."
      count=$((count - 1))
      sleep 1
    done
    [ $count -eq 0 ] && do_action
  elif [[ "$batPerc" -le "$lowThresh" ]] && [[ "$batStat" == "Discharging" ]] && (((lastPerc - batPerc) >= interval)); then
    rounded=$(printf "%1d" $(((batPerc + 5) / 10 * 10)))
    notify-send -a "HYDA Power" -t 5000 -r 5 -u "critical" -i "battery-level-${rounded:-10}-symbolic" "Battery Low" "Battery is at $batPerc%. Connect the charger."
    lastPerc=$batPerc
  fi
}

do_action() {
  count=$((timer > mnt ? timer : mnt))
  nohup "$exCrit" &>/dev/null &
}

do_stat() {
  if [[ $batPerc -ge $fullThresh ]] && [[ "$batStat" != *"Discharging"* ]]; then
    echo "Full and $batStat"
    batStat="Full"
  fi
  case "$batStat" in
    "Discharging")
      if [[ "$prevStat" != "Discharging" ]] || [[ "$prevStat" == "Full" ]]; then
        prevStat=$batStat
        urgency=$([[ $batPerc -le "$lowThresh" ]] && echo "critical" || echo "normal")
        rounded=$(printf "%1d" $(((batPerc + 5) / 10 * 10)))
        notify-send -a "HYDA Power" -t 5000 -r 5 -u "${urgency:-normal}" -i "battery-level-${rounded:-10}-symbolic" "Charger Unplugged" "Battery is at $batPerc%."
        $exDis
      fi
      do_perc
      ;;
    "Not"* | "Charging")
      if [[ "$prevStat" == "Discharging" ]] || [[ "$prevStat" == "Not"* ]]; then
        prevStat=$batStat
        count=$((timer > mnt ? timer : mnt))
        urgency=$([[ "$batPerc" -ge $unThresh ]] && echo "critical" || echo "normal")
        rounded=$(printf "%1d" $(((batPerc + 5) / 10 * 10)))
        notify-send -a "HYDA Power" -t 5000 -r 5 -u "${urgency:-normal}" -i "battery-level-${rounded:-100}-charging-symbolic" "Charger Plugged" "Battery is at $batPerc%."
        $exChar
      fi
      do_perc
      ;;
    "Full")
      if [[ $batStat != "Discharging" ]]; then
        now=$(date +%s)
        if [[ "$prevStat" == *"harging"* ]] || ((now - lt >= $((notify * 60)))); then
          notify-send -a "HYDA Power" -t 5000 -r 5 -u "critical" -i "battery-full-charging-symbolic" "Battery Full" "Please unplug your charger"
          prevStat=$batStat lt=$now
          $exChar
        fi
      fi
      ;;
    *)
      do_perc
      ;;
  esac
}

get_bat() {
  totPerc=0 batCount=0
  for battery in /sys/class/power_supply/BAT*; do
    batStat=$(<"$battery/status") batPerc=$(<"$battery/capacity")
    totPerc=$((totPerc + batPerc))
    batCount=$((batCount + 1))
  done
  batPerc=$(( totPerc / batCount))
}

do_change() {
  get_bat
  local exLow=false
  local exUn=false
  if [ "$batStat" != "$lastStat" ] || [ "$batPerc" != "$lastPerc" ]; then
    lastStat=$batStat
    lastPerc=$batPerc
    do_perc
    if [[ "$batPerc" -le "$lowThresh" ]] && ! $exLow; then
      $exLow
      exLow=true exUn=false
    fi
    if [[ "$batPerc" -ge "$unThresh" ]] && ! $exUn; then
      $exUn
      exUn=true exLow=false
    fi
  fi
}

main() {
    fullThresh=${BATTERY_NOTIFY_THRESHOLD_FULL:-100}
    critThresh=${BATTERY_NOTIFY_THRESHOLD_CRITICAL:-5}
    unThresh=${BATTERY_NOTIFY_THRESHOLD_UNPLUG:-80}
    lowThresh=${BATTERY_NOTIFY_THRESHOLD_LOW:-20}
    timer=${BATTERY_NOTIFY_TIMER:-120}
    notify=${BATTERY_NOTIFY_NOTIFY:-1140}
    interval=${BATTERY_NOTIFY_INTERVAL:-5}
    exCrit=${BATTERY_NOTIFY_EXECUTE_CRITICAL:-"systemctl suspend"}
    exLow=${BATTERY_NOTIFY_EXECUTE_LOW:-}
    exUn=${BATTERY_NOTIFY_EXECUTE_UNPLUG:-}
    exChar=${BATTERY_NOTIFY_EXECUTE_CHARGING:-}
    exDis=${BATTERY_NOTIFY_EXECUTE_DISCHARGING:-}
    
    usage
    get_bat
    lastPerc=$batPerc
    prevStat=$batStat
    dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',path='$(upower -e | grep battery)'" 2>/dev/null | while read -r battery_status_change; do do_change; done
}

case "$1" in
  *)
    usage
    exit 0
    ;;
esac

main
