#!/usr/bin/env bash

do_mute() {
  if [[ "$cur_stat" == "yes" ]]; then
    icon="audio-volume-muted-symbolic"
    text="Audio Mute On"
  else
    icon="audio-volume-high-symbolic"
    text="Audio Mute Off"
  fi
  notify-send -e "Volume" "$text" -i "$icon" -a "HYDA Volume" -r 9984 -h string:synchronous:volume
}

do_mic_mute() {
  if [[ "$cur_mic_stat" == "yes" ]]; then
    icon="microphone-disabled-symbolic"
    text="Mic Mute On"
  else
    icon="microphone-access-symbolic"
    text="Mic Mute Off"
  fi
  notify-send -e "Volume" "$text" -i "$icon" -a "HYDA Volume" -r 9984 -h string:synchronous:volume
}

do_volume() {
  if (( cur_vol <= 0 )); then
    icon="audio-volume-muted-symbolic"
  elif (( cur_vol < 20 )); then
    icon="audio-volume-low-symbolic"
  elif (( cur_vol <= 60 )); then
    icon="audio-volume-medium-symbolic"
  else
    icon="audio-volume-high-symbolic"
  fi
  text="<big>====<b>${cur_vol}%</b>====</big>"
  notify-send -e "Volume" "$text" -i "$icon" -a "HYDA Volume" -r 9984 -h string:synchronous:volume -h int:value:"$cur_vol"
}

do_mic_volume() {
  if (( cur_mic_vol <= 0 )); then
    icon="microphone-sensitivity-muted-symbolic"
  elif (( cur_mic_vol < 20 )); then
    icon="microphone-sensitivity-low-symbolic"
  elif (( cur_mic_vol <= 60 )); then
    icon="microphone-sensitivity-medium-symbolic"
  else
    icon="microphone-sensitivity-high-symbolic"
  fi
  text="<big>====<b>${cur_mic_vol}%</b>====</big>"
  notify-send -e "Volume" "$text" -i "$icon" -a "HYDA Volume" -r 9984 -h string:synchronous:volume -h int:value:"$cur_mic_vol"
}

handle() {
  cur_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1)
  cur_mic_vol=$(pactl get-source-volume @DEFAULT_SOURCE@ | awk '{print $5}' | head -n1)
  cur_vol=${cur_vol%\%}
  cur_mic_vol=${cur_mic_vol%\%}
  cur_stat=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
  cur_mic_stat=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
  
  if [[ "$cur_stat" != "$prev_stat" ]]; then
    do_mute
    prev_stat="$cur_stat"
  fi

  if [[ "$cur_vol" != "$prev_vol" ]]; then
    do_volume
    prev_vol="$cur_vol"
  fi

  if [[ "$cur_mic_stat" != "$prev_mic_stat" ]]; then
    do_mic_mute
    prev_mic_stat="$cur_mic_stat"
  fi
  
  if [[ "$cur_mic_vol" != "$prev_mic_vol" ]]; then
    do_mic_volume
    prev_mic_vol="$cur_mic_vol"
  fi
}

main() {
  prev_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1)
  prev_mic_vol=$(pactl get-source-volume @DEFAULT_SOURCE@ | awk '{print $5}' | head -n1)
  prev_vol=${prev_vol%\%}
  prev_mic_vol=${prev_mic_vol%\%}
  prev_stat=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
  prev_mic_stat=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')
 
  pactl subscribe | grep --line-buffered "Event 'change' on sink\|source" | while read -r volume_change; do handle; done
}

[ $# -gt 0 ] && usage || main
