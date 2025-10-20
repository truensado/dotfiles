#!/usr/bin/env bash
# description: cli wallpaper manager

usage() {
  cat <<EOF

${bold}Hyda Updater${reset} — cli tool for managing updates

${bold}Usage:${reset}
  ${bold}restore${reset},   -r,   --restore   ${info}restores wallpaper${reset}
  ${bold}reset${reset},     -rs,  --reset     ${info}deletes wallpaper cache${reset}
  ${bold}help${reset},      -h,   --help      ${info}prints this help${reset}
  ${bold}backend${reset},   -b,   --backend   ${info}overrides wallpaper engine to use${reset}
  ${bold}dir${reset},       -d,   --dir       ${info}overrides wallpaper directory to choose from${reset}

${bold}Example:${reset}
EOF
}

get_backend() {
  case "$backend" in
    hyprpaper) do_hypr ;;
    swww) do_swww ;;
    *)
      log_error "unknown backend chosen - only hyprpaper and swww supported"
      notify-send -e "Unknown backend chosen" -i "preferences-desktop-wallpaper-symbolic"
      ;;
  esac
}

do_reset() {
  for f in ${hyda_cache}/wall.*; do
    rm "$f"
  done
  log_info "reset wall cache"
  exit 0
}

do_reload() {
  for f in ${hyda_cache}/wall.*; do
    local file_name=$(basename "$f")
    wall="$(readlink -f "$f")"
    mon="${file_name#wall.}"
    get_backend
  done
  exit 0
}

do_hypr() {
  hyprctl hyprpaper reload "$mon","$wall" &>/dev/null \
  && log_success "wall set" || log_error "failed to set wall"
  return 0
}

do_wall() {
  local monitors choice
  monitors=$(hyprctl monitors -j | jq -r '.[].name')
  monitors=$(printf 'Monitor: %s\n' $monitors | rofi -dmenu -theme "${ROFI_PROMPT_THEME}" -p "Choose Monitor")
  monitors=${monitors#Monitor: }

  [[ -z "$monitors" ]] && log_info "no monitor selected" && exit 1
  
  wall=$(find "$wall_dir" -type f)
  
  while IFS= read -r img; do
    fname=$(basename "$img")
    entries+="$fname\0icon\x1f$img\n"
  done <<< "$wall"

  local choice=$(printf "%b" "$entries" | rofi -dmenu -show-icon -theme "${ROFI_SELECTOR_THEME}")
  
  [[ -z "$choice" ]] && log_info "no wallpaper selected" && exit 1
  
  wall=$(printf '%s\n' "$wall" | grep "/$choice" | head -n1)
  mon="$monitors"

  ln -sf "$wall" "${hyda_cache}/wall.$mon"

  get_backend
}

main() {
  wall_dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/wallpapers"

  if command -v hyprpaper &>/dev/null; then
    backend="hyprpaper"
  elif command -v swww &>/dev/null; then
    backend="swww"
  else
    log_error "no wallpaper backend found - install hyprpaper or swww to proceed"
    notify-send -e "No wallpaper backend found" -i "preferences-desktop-wallpaper-symbolic"
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      *backend | -b)
        backend="$2"
        shift 2
        ;;
      *dir | -d)
        [[ ! -d "$2" ]] && log_error "not a directory: '${2}'" && exit 1
        wall_dir="$2" && log_success "wallpaper directory set as '${2}'"
        shift 2
        ;;
      *restore | -r) do_reload ;;
      *reset | -rs) do_reset ;;
      *help | -h) usage && exit 0 ;;
      *)
        log_error "unknown argument: $1"
        echo
        usage
        exit 1
        ;;
    esac
  done

  do_wall
}

main "$@"
