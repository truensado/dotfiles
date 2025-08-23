#!/usr/bin/env bash

if ! grep -q "Battery" /sys/class/power_supply/BAT*/type; then
  echo "not a laptop"
  exit 0
fi

do_action() {
  count=$((timer > mnt ? timer : mnt))
  nohup "$exCrit" &>/dev/null &
}

get_perc() {
  local charging=""
  if [[ "$batPerc" -ge "$unplugThreshold" ]] && [[ "$batStat" != "Discharging" ]] && [[ "$batStat" != "Full" ]] && (((batPerc - lastPerc) >= interval)); then
    notify-send -a "Hyda Power" -t 5000 -r 5 -u "critical" -i "battery-level-100-charged-symbolic" "Battery Charged" "Battery is at $batPerc%. You can unplug the charger."
    lastPerc=$batPerc
  elif [[ "$batPerc" -le "$batCritThreshold" ]]; then
    count=$((timer > mnt ? timer : mnt))
    while [ $count -gt 0 ] && [[ $batStat == "Discharging"* ]]; do
      for battery in /sys/class/power_supply/BAT*; do batStat=$(<"$battery/status"); done
      if [[ $batStat != "Discharging" ]]; then break; fi
      notify-send -a "Hyda Power" -t 5000 -r 5 -u "critical" -i "battery-level-0-symbolic" "Battery Critical" "$batPerc% is critically low. Device will execute $exCrit in $((count / 60)):$((count % 60)) ."
      count=$((count - 1))
      sleep 1
    done
    [ $count -eq 0 ] && do_action
  elif [[ "$batPerc" -le "$batLowThreshold" ]] && [[ "$batStat" == "Discharging" ]] && (((lastPerc - batPerc) >= interval)); then
    rounded=$(printf "%1d" $(((batPerc + 5) / 10 * 10)))
    notify-send -a "Hyda Power" -t 5000 -r 5 -u "critical" -i "battery-level-${rounded:-10}-symbolic" "Battery Low" "Battery is at $batPerc%. Connect the charger."
    lastPerc=$batPerc
  fi
}

get_stat() {
  if [[ $batPerc -ge $batFullThreshold ]] && [[ "$batStat" != *"Discharging"* ]]; then
    echo "Full and $batStat"
    batStat="Full"
  fi
  case "$batStat" in
    "Discharging")
      if [[ "$prevStat" != "Discharging" ]] || [[ "$prevStat" == "Full" ]]; then
        prevStat=$batStat
        urgency=$([[ $batPerc -le "$batLowThreshold" ]] && echo "critical" || echo "normal")
        rounded=$(printf "%1d" $(((batPerc + 5) / 10 * 10)))
        notify-send -a "Hyda Power" -t 5000 -r 5 -u "${urgency:-normal}" -i "battery-level-${rounded:-10}-symbolic" "Charged Disconnected" "Battery is at $batPerc%."
        $exDischarg
      fi
      get_perc
      ;;
    "Not"* | "Charging")
      if [[ "$prevStat" == "Discharging" ]] || [[ "$prevStat" == "Not"* ]]; then
        prevStat=$batStat
        count=$((timer > mnt ? timer : mnt))
        urgency=$([[ "$batPerc" -ge $unplugThreshold ]] && echo "critical" || echo "normal")
        rounded=$(printf "%1d" $(((batPerc + 5) / 10 * 10)))
        [[ "$rounded" = "100" ]] && local charState="charged" || local charState="charging"
        notify-send -a "Hyda Power" -t 5000 -r 5 -u "${urgency:-normal}" -i "battery-level-${rounded:-100}-$charState-symbolic" "Charger Connected" "Battery is at $batPerc%."
        $exCharg
      fi
      get_perc
      ;;
    "Full")
      if [[ $batStat != "Discharging" ]]; then
        now=$(date +%s)
        if [[ "$prevStat" == *"harging"* ]] || ((now - lt >= $((notify * 60)))); then
          notify-send -a "Hyda Power" -t 5000 -r 5 -u "critical" -i "battery-full-charging-symbolic" "Battery Full" "Please unplug your charger."
          prevStat=$batStat lt=$now
          $exCharg
        fi
      fi
      ;;
    *)
      get_perc
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
  batPerc=$((totPerc / batCount))
}

do_statChange() {
  get_bat
  local exLow=false
  local exUnplug=false

  if [ "$batStat" != "$lastBatStat" ] || [ "$batPerc" != "$lastBatPerc" ]; then
    lastBatStat=$batStat
    lastBatPerc=$batPerc
    get_perc
    if [[ "$batPerc" -le "$batLowThreshold" ]] && ! $exLow; then
      $exLow
      exLow=true exUnplug=false
    fi
    if [[ "$batPerc" -ge "$unplugThreshold" ]] && ! $exUnplug; then
      $exUnplug
      exUnplug=true exLow=false
    fi
    get_stat
  fi
}

main() {
  batFullThreshold=${BATTERY_NOTIFY_THRESHOLD_FULL:-100}
  batCritThreshold=${BATTERY_NOTIFY_THRESHOLD_CRITICAL:-5}
  unplugThreshold=${BATTERY_NOTIFY_THRESHOLD_UNPLUG:-80}
  batLowThreshold=${BATTERY_NOTIFY_THRESHOLD_LOW:-20}
  timer=${BATTERY_NOTIFY_TIMER:-120}
  notify=${BATTERY_NOTIFY_NOTIFY:-1140}
  interval=${BATTERY_NOTIFY_INTERVAL:-5}
  exCrit=${BATTERY_NOTIFY_EXECUTE_CRITICAL:-"systemctl suspend"}
  exLow=${BATTERY_NOTIFY_EXECUTE_LOW:-}
  exUnplug=${BATTERY_NOTIFY_EXECUTE_UNPLUG:-}
  exCharg=${BATTERY_NOTIFY_EXECUTE_CHARGING:-}
  exDischarg=${BATTERY_NOTIFY_EXECUTE_DISCHARGING:-}

  get_bat
  
  lastPerc=$batPerc
  prevStat=$batStat

  dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',path='$(upower -e | grep battery)'" 2>/dev/null | while read -r batStatChange; do do_statChange; done
  
}

main
