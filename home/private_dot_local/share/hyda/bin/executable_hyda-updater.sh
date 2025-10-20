#!/usr/bin/env bash
# description: cli system updater

usage() {
  cat <<eof

${bold}Hyda Updater${reset} — cli tool for managing updates

${bold}Usage:${reset}
  ${bold}waybar${reset},  -w, --waybar  ${info}prints waybar json for custom/updates${reset}
  ${bold}notify${reset},  -n, --notify  ${info}sends a notification to update${reset}
  ${bold}help${reset},    -h, --help    ${info}prints this help page${reset}
  ${bold}*${reset},                     ${info}performs update if there is any${reset}

${bold}Example:${reset}
  hydacli updater --notify
  hydacli updater waybar
  hydacli updater
eof
}

do_notify() {
  local urgency="${1:-normal}" text="${2:-}"
  notify-send -e -u "$urgency" -a "Hyda Updater" -r 9996 -i "$icon" "$text" -h string:synchronous:update
}

get_deps() {
  local deps=(topgrade)
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      log_error "missing dependency: ${bold}$dep${reset}"
      do_notify "critical" "Missing Dependency: $dep"
      exit 1
    fi
  done
}

check_updates() {
  do_time
  if (( diff >= interval )); then
    refresh_cache
  else
    ofc=$(hyda_state_get "Update Cache" "official")
    aur=$(hyda_state_get "Update Cache" "aur")
  fi
 [[ -z "$ofc" || -z "$aur" ]] && refresh cache
}

refresh_cache() {
  get_ofc
  get_aur
  last=$(date +%s)
  hyda_state "Update Cache" "time" "$last"
}

do_time() {
  interval=3600
  now=$(date +%s)
  last=$(hyda_state_get "Update Cache" "time")
  [[ -z "$last" ]] && diff=$interval || diff=$(( now - last ))
}

get_ofc() {
  ofc=$(checkupdates 2>/dev/null | wc -l)
  hyda_state "Update Cache" "official" "$ofc"
}

get_aur() {
  local helper
  for helper in paru yay; do
    if command -v "$helper" &>/dev/null; then
      aur=$("$helper" -qua 2>/dev/null | wc -l)
      hyda_state "Update Cache" "aur" "$aur"
      return
    fi
  done
  aur=0
}

do_waybar() {
  check_updates
  local total=$((ofc + aur))
  if (( total > 0 )); then
    echo "{\"text\":\" $total\",\"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur\"}"
  else
    echo "{\"text\":\"\", \"tooltip\":\" Packages are up to date\"}"
  fi
}

launch_update() {
  "$term" --class=com.systemupdate --title="System Update" \
  --initial-command="echo -e '${bold}Starting Update${reset}'; \
  if topgrade --skip-notify --only system; then
    do_notify 'normal' '✅ System Update Complete';
  else
    do_notify 'critical' '❌ System Update Failed';
  fi"

  refresh_cache

  systemctl --user restart waybar
}

notify_updates() {
  check_updates
  local title msg
  if (( ofc > 0 && aur > 0 )); then
    title="Updates Available"; msg="System: $ofc\nAUR: $aur"
  elif (( ofc > 0 )); then
    title="System Updates Available"; msg="System: $ofc"
  elif (( aur > 0 )); then
    title="AUR Updates Available"; msg="AUR: $aur"
  else
    log_info "no updates available."
    do_notify "normal" "System is up to date"
    return
  fi
  read -t 5 action < <(
    notify-send -e -u "critical" -a "Hyda Updater" -r 9996 \
    -i "$icon" "$title" "$msg" --action="update=Update Now" --action="dismiss=Dismiss" 2>/dev/null
  )
  [[ "$action" == "update" ]] && launch_update || exit 0
}

main() {
  icon="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
  term="${TERMINAL:-ghostty}"
  get_deps
  case "$1" in
    *waybar | -w) do_waybar ;;
    *notify | -n) notify_updates ;;
    *help | -h) usage ;;
    *refresh | -r) refresh_cache ;;
    *)
      check_updates
      if (( ofc > 0 || aur > 0 )); then
        launch_update
      else
        log_info "no updates available."
        do_notify "normal" "No updates available"
      fi
      ;;
  esac
}

main "$@"
