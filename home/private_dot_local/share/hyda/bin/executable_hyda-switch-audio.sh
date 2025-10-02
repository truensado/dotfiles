#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"

filter=(
  "alsa_output.pci-0000_00_1f.3.iec958-stereo"
  "alsa_output.pci-0000_01_00.1.hdmi-stereo"
  "alsa_output.pci-0000_00_1f.3.iec958-stereo.monitor"
  "alsa_input.pci-0000_00_1f.3.analog-stereo"
  "alsa_output.pci-0000_01_00.1.hdmi-stereo.monitor"
  "alsa_output.usb-Generic_USB2.0_Device_20170726905923-00.analog-stereo.monitor"
  "alsa_input.usb-Generic_USB2.0_Device_20170726905923-00.mono-fallback"
)

sources=$(pactl list short sources | awk '{print $2}' | grep -vFf <(printf "%s\n" "${filter[@]}"))
sinks=$(pactl list short sinks | awk '{print $2}' | grep -vFf <(printf "%s\n" "${filter[@]}"))

[[ -z "$sinks" && -z "$sources" ]] && { echo -e "${error}no sinks or sources available"; exit 1; }

usage() {
  cat <<'EOF'

Hyda-Switch-Audio — Changes Audio Sink or Source

Usage:
 list         -l  ->  Lists available sinks while filtered
 switch       -s  ->  Use with source or sink to cycle through either
EOF
}

switch_sink() {
  [[ -z "$sinks" ]] && { echo -e "${error}no sinks available"; return 1; }

  local current next idx=-1 i
 
  current="$(pactl info | awk '/Default Sink:/ {print $3}')"

  mapfile -t sinks_array <<< "$sinks"

  for i in "${!sinks_array[@]}"; do
    if [[ "${sinks_array[$i]}" == "$current" ]]; then
      idx=$i
      break
    fi
  done

  next="${sinks_array[$(((idx + 1) % ${#sinks_array[@]}))]}"

  pactl set-default-sink "$next"
  notify-send -e "Switched Sink:" "$next" -i "audio-speakers-symbolic" -a "Hyda Devices" -r 9998 -h string:synchronous:sinks -t 3000
  echo -e "${success}Switched sink to${reset}: $next"
}

switch_source() {
  [[ -z "$sources" ]] && { echo -e "${error}no sources available"; return 1; }

  local current next idx=-1 i
 
  current="$(pactl info | awk '/Default Source:/ {print $3}')"

  mapfile -t sources_array <<< "$sources"

  for i in "${!sources_array[@]}"; do
    if [[ "${sources_array[$i]}" == "$current" ]]; then
      idx=$i
      break
    fi
  done

  next="${sources_array[$(((idx + 1) % ${#sources_array[@]}))]}"

  pactl set-default-source "$next"
  notify-send -e "Switched Source:" "$next" -i "audio-input-microphone-symbolic" -a "Hyda Devices" -r 9998 -h string:synchronous:sources -t 3000
  echo -e "${success}Switched source to${reset}: $next"
}

while (($#)); do
  case $1 in
    list | -l)
      [[ -n "$sinks" ]] && echo -e "${bold}List of Sinks${reset}:\n$sinks\n"
      [[ -n "$sources" ]] && echo -e "${bold}List of Sources${reset}:\n$sources"
      shift
      ;;
    switch | -s)
      case "${2:-}" in
        sink | sinks)
          switch_sink
          shift
          ;;
        source | sources)
          switch_source
          shift
          ;;
        *)
          echo -e "${error}unknown switch target: '$2' (expected 'sink' or 'source')"
          usage
          exit 1
          ;;
      esac
      shift
      ;;
    help | -h | --help | -help)
      usage
      shift
      ;;
    *)
      echo -e "${error}unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done
