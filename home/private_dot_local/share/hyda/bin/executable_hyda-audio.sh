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

main() {
  local cur_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1)
  local cur_vol=${cur_vol%\%}
  local cur_stat=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')
  if [[ "$cur_stat" != "$prev_stat" ]]; then
    do_mute
    prev_stat="$cur_stat"
  elif [[ "$cur_vol" != "$prev_vol" ]]; then
    do_volume
    prev_vol="$cur_vol"
  fi
}

pactl subscribe | while read -r volume_change; do main; done
