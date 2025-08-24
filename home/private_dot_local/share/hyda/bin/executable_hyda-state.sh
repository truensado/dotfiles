#!/usr/bin/env bash

state_file="${XDG_CACHE_HOME:-$HOME/.cache}/hyda/state.lock"

header="${1:-}"
value="${2:-}"

usage() {
  cat <<'EOF'

Hyda-State — Script Utility for State.lock

Usage:
 "Command 1"      ->  Sets the Header
 "Command 2"      ->  Sets the Value
EOF
}

set_state_lock() {
  
  local header="${1:-}" value="${2:-}"

  if [[ -z "$header" || -z "$value" ]]; then
    usage; return 2
  fi

  mkdir -p "$(dirname "$state_file")"
  touch "$state_file"

  if grep -qxF "[$header]" "$state_file"; then
    tmp="$(mktemp)"
    awk -v H="[$header]" -v V="$value" '
      # if previous line was header, replace this line with V
      p { print V; p=0; next }
      { print }
      $0==H { p=1 }
    ' "$state_file" > "$tmp"
    mv "$tmp" "$state_file"
  else
    if [[ -s "$state_file" ]]; then
      printf "\n[%s]\n%s\n" "$header" "$value" | tee -a "$state_file" >/dev/null
    else
      printf "[%s]\n%s\n" "$header" "$value" | tee -a "$state_file" >/dev/null
    fi
  fi
}

