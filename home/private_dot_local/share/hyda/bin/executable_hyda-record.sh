#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"

srDir="${XDG_VIDEOS_DIR:-$HOME/Videos}/screenrecords"

do_record() {
  local file="$srDir/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  local region=$(slurp -o)

  [[ -z "$region" ]] && { notify-send -e "Screen recording cancelled" -i "replay-record-error" -t 3000; exit 1; }
  
  if lspci | grep -qi 'nvidia'; then
    wf-recorder --audio=$(pactl get-default-sink).monitor -g "$region" -f "$file" -c libx264 -p crf=23 -p preset=medium -p movflags=+faststart &
  else
    wf-recorder --audio=$(pactl get-default-sink).monitor -g "$region" -f "$file" --ffmpeg-encoder-options="-c:v libx264 -crf 23 -preset medium -movflags +faststart" &
  fi
}

stop_record() {
  pkill -x wf-recorder
}

do_deps() {
  local deps=(wf-recorder slurp)

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo -e "${error}Error${reset}: Missing dependency ${bold}$dep"
      notify-send -e "Missing dependency $dep"
      exit 1
    fi
  done
}

mkdir -p "$srDir"

do_deps

if pgrep -x wf-recorder >/dev/null; then
  stop_record
  notify-send -e "Screen recording saved to $srDir" -i "screencast-recorded-symbolic" -t 3000
else
  do_record
  notify-send -e "Screen recording started" -i "replay-record" -t 3000
fi
