#!/usr/bin/env bash
# description: spotify daemon for waybar

handle() {
  local title=$(jq -r '.title // empty' <<< "$1")
  local artist=$(jq -r '.artist // empty' <<< "$1")
  local album=$(jq -r '.album // empty' <<< "$1")

  if [[ -z "$title" ]]; then
    echo "{\"text\":\"\", \"tooltip\":\"\"}"
  else
    echo "{\"text\":\" \",\"tooltip\":\"$title\n $artist\n $album\"}"
  fi
}

main() {
  if ! command -v playerctl &>/dev/null; then
    log_error "playerctl not found — install it to use"
    exit 1
  fi

  log_info "Hyda Spotify daemon started"
  playerctl -p spotify --follow metadata --format '{"artist": "{{artist}}", "title": "{{title}}", "album": "{{album}}"}' | while read -r line; do handle "$line"; done
}

if [[ $# -gt 0 ]]; then
  log_error "hyda spotify daemon doesn't require arguments — just run it as is"
  exit 1
else
  main
fi
