#!/usr/bin/env bash
# description: switch between audio sinks and sources interactively

filter=(
  "alsa_output.pci-0000_00_1f.3.iec958-stereo"
  "alsa_output.pci-0000_01_00.1.hdmi-stereo"
  "alsa_output.pci-0000_00_1f.3.iec958-stereo.monitor"
  "alsa_input.pci-0000_00_1f.3.analog-stereo"
  "alsa_output.pci-0000_01_00.1.hdmi-stereo.monitor"
  "alsa_output.usb-Generic_USB2.0_Device_20170726905923-00.analog-stereo.monitor"
  "alsa_input.usb-Generic_USB2.0_Device_20170726905923-00.mono-fallback"
)

usage() {
  cat <<EOF

${bold}Hyda Audio Switcher${reset} — cli tool for cycling audio devices

${bold}Usage:${reset}
  ${bold}list${reset},    -l, --list    ${info}list all sinks/sources${reset}
  ${bold}switch${reset},  -s, --switch  ${info}cyle through available devices${reset} (${bold}sink/source${reset})

${bold}Example:${reset}
  hydacli switch-audio list
  hydacli switch-audio switch ${info}sink${reset}
  hydacli switch-audio switch ${info}source${reset}
EOF
}

get_sinks() {
  pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -vFf <(printf "%s\n" "${filter[@]}")
}

get_sources() {
  pactl list short sources 2>/dev/null | awk '{print $2}' | grep -vFf <(printf "%s\n" "${filter[@]}")
}

do_notify() {
  local title="$1"
  local text="$2"
  local icon="$3"
  notify-send -e "$title" "$text" -i "$icon" -a "HYDA" -r 9998 -h string:synchronous:switch
}

switch_sink() {
  local sinks current next idx=-1
  mapfile -t sinks < <(get_sinks)
  [[ ${#sinks[@]} -eq 0 ]] && { log_error "No sinks available"; return 1; }

  current=$(pactl info | awk '/Default Sink:/ {print $3}')
  for i in "${!sinks[@]}"; do
    [[ "${sinks[$i]}" == "$current" ]] && idx=$i && break
  done
  next="${sinks[$(((idx + 1) % ${#sinks[@]}))]}"

  pactl set-default-sink "$next" 2>/dev/null || { log_error "Failed to switch sink"; return 1; }
  log_success "Switched sink to ${bold}$next${reset}"
  do_notify "Audio Output Changed" "$next" "audio-headphones-symbolic"
}

switch_source() {
  local sources current next idx=-1
  mapfile -t sources < <(get_sources)
  [[ ${#sources[@]} -eq 0 ]] && { log_error "No sources available"; return 1; }

  current=$(pactl info | awk '/Default Source:/ {print $3}')
  for i in "${!sources[@]}"; do
    [[ "${sources[$i]}" == "$current" ]] && idx=$i && break
  done
  next="${sources[$(((idx + 1) % ${#sources[@]}))]}"

  pactl set-default-source "$next" 2>/dev/null || { log_error "Failed to switch source"; return 1; }
  log_success "Switched source to ${bold}$next${reset}"
  do_notify "Audio input Changed" "$next" "audio-headset-symbolic"
}

list_devices() {
  local sinks sources
  sinks=$(get_sinks)
  sources=$(get_sources)

  [[ -z "$sinks" && -z "$sources" ]] && { log_error "No sinks or sources available"; exit 1; }
  
  [[ -n "$sinks" ]] && { echo -e "\n${bold}Sinks:${reset}"; echo "$sinks"; }
  [[ -n "$sources" ]] && { echo -e "\n${bold}Sources:${reset}"; echo "$sources"; }
}

main() {
  case "$1" in
    *list | -l) list_devices ;;
    *switch | -s)
      case "$2" in
        sink) switch_sink ;;
        source) switch_source ;;
        *) log_error "Unknown target '${2:-}' (expected 'sink' or 'source')"; usage; exit 1 ;;
      esac
      ;;
    *help | -h) usage ;;
    *) log_error "Unknown argument: $1"; usage; exit 1 ;;
  esac
}

main "$@"
