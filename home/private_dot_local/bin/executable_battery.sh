#!/usr/bin/env bash

set -euo pipefail

dock=false
[[ "${BATTERY_NOTIFY_DOCK:-}" == "true" ]] && dock=true

battery_full_threshold=${BATTERY_NOTIFY_THRESHOLD_FULL:-100}
battery_critical_threshold=${BATTERY_NOTIFY_THRESHOLD_CRITICAL:-5}
unplug_charger_threshold=${BATTERY_NOTIFY_THRESHOLD_UNPLUG:-80}
battery_low_threshold=${BATTERY_NOTIFY_THRESHOLD_LOW:-20}
timer=${BATTERY_NOTIFY_TIMER:-120}
notify_interval=${BATTERY_NOTIFY_NOTIFY:-1140}
interval_step=${BATTERY_NOTIFY_INTERVAL:-5}
execute_critical=${BATTERY_NOTIFY_EXECUTE_CRITICAL:-"systemctl suspend"}
execute_low=${BATTERY_NOTIFY_EXECUTE_LOW:-}
execute_unplug=${BATTERY_NOTIFY_EXECUTE_UNPLUG:-}
execute_charging=${BATTERY_NOTIFY_EXECUTE_CHARGING:-}
execute_discharging=${BATTERY_NOTIFY_EXECUTE_DISCHARGING:-}

verbose=false
[[ "${1:-}" == "-v" || "${1:-}" == "--verbose" ]] && verbose=true

log() { $verbose && echo "$1"; }

# Function: get averaged battery percentage and status
get_battery_info() {
    local total=0 count=0 status=""
    for battery in /sys/class/power_supply/BAT*; do
        [[ -r "$battery/capacity" && -r "$battery/status" ]] || continue
        status=$(<"$battery/status")
        total=$((total + $(<"$battery/capacity")))
        count=$((count + 1))
    done
    if (( count == 0 )); then
        echo "Unknown 0"
    else
        echo "$status $((total / count))"
    fi
}

# Function: show a notification
notify_battery() {
    local urgency="$1" icon="$2" title="$3" message="$4"
    notify-send -a "Battery Monitor" -t 5000 -r 5 -u "$urgency" -i "$icon" "$title" "$message"
}

# Function: execute command string safely
run_command() {
    local cmd="$1"
    [[ -n "$cmd" ]] && nohup bash -c "$cmd" &>/dev/null &
}

# Battery logic handler
handle_battery() {
    local status="$1"
    local percentage="$2"
    local now
    steps=$(printf "%03d" $(((percentage + 5) / 10 * 10)))

    if [[ "$status" != "Discharging" && "$status" != "Full" && "$percentage" -ge "$unplug_charger_threshold" ]]; then
        notify_battery "CRITICAL" "battery-${steps}-charging" "Battery Charged" "Battery at $percentage% — unplug charger"
        run_command "$execute_unplug"
    elif [[ "$percentage" -le "$battery_critical_threshold" && "$status" == "Discharging" ]]; then
        for ((count=timer; count>0; count--)); do
            read -r status _ <<< "$(get_battery_info)"
            [[ "$status" != "Discharging" ]] && break
            notify_battery "CRITICAL" "xfce4-battery-critical" "Battery Critically Low" "$percentage% remaining — suspending in $((count / 60)):$((count % 60))"
            sleep 1
        done
        ((count == 0)) && run_command "$execute_critical"
    elif [[ "$percentage" -le "$battery_low_threshold" && "$status" == "Discharging" ]]; then
        notify_battery "CRITICAL" "battery-level-${steps}-symbolic" "Battery Low" "Battery at $percentage% — connect charger"
        run_command "$execute_low"
    fi
}

# Status transition handler
handle_status_change() {
    local status="$1"
    local percentage="$2"
    local urgency steps
    steps=$(printf "%03d" $(((percentage + 5) / 10 * 10)))

    case "$status" in
        Discharging)
            urgency=$([[ "$percentage" -le "$battery_low_threshold" ]] && echo "CRITICAL" || echo "NORMAL")
            notify_battery "$urgency" "battery-level-${steps}-symbolic" "Charger Unplugged" "Battery at $percentage%"
            run_command "$execute_discharging"
            ;;
        Charging|Not*)
            urgency=$([[ "$percentage" -ge "$unplug_charger_threshold" ]] && echo "CRITICAL" || echo "NORMAL")
            notify_battery "$urgency" "battery-${steps}-charging" "Charger Plugged In" "Battery at $percentage%"
            run_command "$execute_charging"
            ;;
        Full)
            now=$(date +%s)
            notify_battery "CRITICAL" "battery-full-charging-symbolic" "Battery Full" "Please unplug your charger"
            run_command "$execute_charging"
            ;;
        *)
            notify_battery "NORMAL" "dialog-information" "Unknown Battery Status" "$status"
            ;;
    esac
}

# Main monitor loop
main() {
    read -r last_status last_percentage <<< "$(get_battery_info)"

    if ! $dock; then
        battery_path=$(upower -e | grep battery | head -n1 || true)
        [[ -z "$battery_path" ]] && { echo "No battery path found"; exit 1; }

        dbus-monitor --system "type='signal',interface='org.freedesktop.DBus.Properties',path='$battery_path'" 2>/dev/null | \
        while read -r _; do
            read -r status percentage <<< "$(get_battery_info)"
            if [[ "$status" != "$last_status" ]]; then
                last_status="$status"
                handle_status_change "$status" "$percentage"
            fi
            if (( abs = percentage - last_percentage, abs < 0 ? abs = -abs : 1 )) && (( abs >= interval_step )); then
                last_percentage="$percentage"
                handle_battery "$status" "$percentage"
            fi
        done
    fi
}

main
