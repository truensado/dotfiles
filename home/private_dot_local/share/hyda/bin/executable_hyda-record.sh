#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"

scr_dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/screenrecords"

start_record() {
  local file="$scr_dir/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  if lspci | grep -qi 'nvidia'; then
    wf-recorder --audio="$(pactl get-default-sink).monitor" -g "$region" -f "$file" -c libx264 -p crf=23 -p preset=medium -p movflags=+faststart &
  else
    wf-recorder --audio="$(pactl get-default-sink).monitor" -g "$region" -f "$file" --ffmpeg-encoder-options="-c:v libx264 -crf 23 -preset medium -movflags +faststart" &
  fi
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

main() {
  mkdir -p "$scr_dir"
  do_deps
  if pgrep -x wf-recorder >/dev/null; then
    pkill -x wf-recorder && notify-send -e "Screen recording saved to $scr_dir" -i "screencast-recorded-symbolic" -t 3000
  else
    region=$(slurp -o 2>/dev/null) || { notify-send -e "Screen recording cancelled" -i "replay-record-error" -t 3000; exit 1; }
    start_record && notify-send -e "Screen recording started" -i "replay-record" -t 3000
  fi
}

main
