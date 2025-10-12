#!/usr/bin/env bash
# description: take and edit screenshots

do_deps() {
  local deps=(grim slurp satty wl-copy)

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      log_error "Missing dependency: ${bold}$dep${reset}"
      exit 1
    fi
  done
}

main() {
  do_deps
  
  trap 'pkill -x slurp &>/dev/null || true' EXIT
 
  local ss_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/screenshots"
  local ss_file="$ss_dir/screenshot-$(date +'%Y%m%d_%H-%M-%S').png"
  
  mkdir -p "$ss_dir"

  log_info "Capturing screenshot..."
  if grim -g "$(slurp -o 2>/dev/null)" -t ppm - | satty \
    --filename - \
    --actions-on-enter save-to-clipboard \
    --save-after-copy \
    --early-exit \
    --copy-command wl-copy \
    --output-filename "$ss_file" \
    &>/dev/null; then
    if [[ ! -f "$ss_file" ]]; then
      log_error "screenshot canceled - no file was saved"
      return 1
    else
      log_success "Screenshot saved to: ${bold}$ss_file${reset}"
    fi
  else
    log_error "Screenshot capture failed"
    exit 1
  fi
}

if [[ $# -gt 0 ]]; then
  log_error "hyda screenshot doesn't require arguments — just run it as is"
  exit 1
else
  main
fi
