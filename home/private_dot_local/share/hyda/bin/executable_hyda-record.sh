#!/usr/bin/env bash
# description: start/stop screen recording with wf-recorder

do_deps() {
  local deps=(wf-recorder slurp pactl)
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      log_error "Missing dependency: ${bold}$dep${reset}"
      notify-send -e "Missing dependency" "$dep is required for recording"
      exit 1
    fi
  done
}

start_record() {
  local sr_dir="${XDG_VIDEOS_DIR:-$HOME/Videos}/screenrecords"
  local sr_file="$sr_dir/screenrecording-$(date +'%Y-%m-%d_%H-%M-%S').mp4"
  local sink="$(pactl get-default-sink).monitor"  
  
  mkdir -p "$sr_dir"

  local cmd_base=(wf-recorder --audio="$sink" -g "$region" -f "$sr_file")
  if lspci | grep -qi 'nvidia'; then
    cmd_base+=(-c libx264 -p crf=23 -p preset=medium -p movflags=+faststart)
  else
    cmd_base+=(--ffmpeg-encoder-options="-c:v libx264 -crf 23 -preset medium -movflags +faststart")
  fi

  "${cmd_base[@]}" &
  log_info "Recording started — saving to: ${bold}$sr_file${reset}"
  notify-send -e "Screen Recording" "Recording started" -i "replay-record" -t 3000
}

stop_record() {
  pkill -x wf-recorder && {
    log_success "Recording stopped."
    notify-send -e "Screen Recording" "Recording stopped and saved" -i "screencast-recorded-symbolic" -t 3000
  }
}

main() {
  do_deps

  if pgrep -x wf-recorder &>/dev/null; then
    stop_record
  else
    region=$(slurp -o 2>/dev/null) || { 
      log_warning "Recording cancelled by user."
      notify-send -e "Screen recording cancelled" -i "replay-record-error" -t 3000 
      exit 1 
    }
    start_record
  fi
}

if [[ $# -gt 0 ]]; then
  log_error "hyda record doesn't require arguments — just run it as is"
  exit 1
else
  main
fi
