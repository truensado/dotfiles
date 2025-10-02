#!/usr/bin/env bash

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

playerctl -p spotify --follow metadata --format '{"artist": "{{artist}}", "title": "{{title}}", "album": "{{album}}"}' | while read -r line; do handle "$line"; done
