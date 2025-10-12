#!/usr/bin/env bash
# description: daemon osd for audio changes

if ! command -v pactl &>/dev/null; then
  log_error "pactl not found - ensure PulseAudio or Pipewire is installed"
  exit 1
fi

notify_audio() {
  local icon="$1" title="$2" message="$3"
  notify-send -e "$title" "$message" -i "$icon" -a "HYDA" -r 9984 -h string:synchronous:volume
}

do_mute() {
  local type="$1" state="$2" icon title text

  case "$type" in
    sink)
      title="Volume"
      if [[ "$state" == "yes" ]]; then
        icon="audio-volume-muted-symbolic"
        text="Muted"
      else
        icon="audio-volume-high-symbolic"
        text="Unmuted"
      fi
      ;;
    source)
      title="Microphone"
      if [[ "$state" == "yes" ]]; then
        icon="microphone-disabled-symbolic"
        text="Muted"
      else
        icon="microphone-sensitivity-high-symbolic"
        text="Unmuted"
      fi
      ;;
  esac

  notify_audio "$icon" "$title" "$text"
}

do_vol() {
  local type="$1" value="$2" icon title text

  case "$type" in
    sink)
      title="Volume"
      if (( value <= 0 )); then
        icon="audio-volume-muted-symbolic"
      elif (( value < 20 )); then
        icon="audio-volume-low-symbolic"
      elif (( value <= 60 )); then
        icon="audio-volume-medium-symbolic"
      else
        icon="audio-volume-high-symbolic"
      fi
      ;;
    source)
      title="Microphone"
      if (( value <= 0 )); then
        icon="microphone-sensitivity-muted-symbolic"
      elif (( value < 20 )); then
        icon="microphone-sensitivity-low-symbolic"
      elif (( value <= 60 )); then
        icon="microphone-sensitivity-medium-symbolic"
      else
        icon="microphone-sensitivity-high-symbolic"
      fi
      ;;
  esac

  text="<big>=====<b>${value}%</b>=====</big>"
  notify_audio "$icon" "$title" "$text"
}

update_state() {
  cur_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1 | tr -d '%')
  cur_mic_vol=$(pactl get-source-volume @DEFAULT_SOURCE@ | awk '{print $5}' | head -n1 | tr -d '%')
  cur_stat=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
  cur_mic_stat=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
}

handle_change() {
  update_state

  if [[ "$cur_stat" != "$prev_stat" ]]; then
    do_mute "sink" "$cur_stat"
    prev_stat="$cur_stat"
  fi

  if [[ "$cur_mic_stat" != "$prev_mic_stat" ]]; then
    do_mute "source" "$cur_mic_stat"
    prev_mic_stat="$cur_mic_stat"
  fi

  if [[ "$cur_vol" != "$prev_vol" ]]; then
    do_vol "sink" "$cur_vol"
    prev_vol="$cur_vol"
  fi
  
  if [[ "$cur_mic_vol" != "$prev_mic_vol" ]]; then
    do_vol "source" "$cur_mic_vol"
    prev_mic_vol="$cur_mic_vol"
  fi
}

main() {
  update_state
  prev_vol="$cur_vol"
  prev_mic_vol="$cur_mic_vol"
  prev_stat="$cur_stat"
  prev_mic_stat="$cur_mic_stat"

  pactl subscribe | grep --line-buffered "Event 'change' on sink\|source" | while read -r volume_change; do handle_change; done
}

if [[ $# -gt 0 ]]; then 
  log_error "hyda audio daemon doesn't require argument, just run it as is"
  exit 1
else
  log_info "Hyda Audio Daemon Started"
  main
fi
