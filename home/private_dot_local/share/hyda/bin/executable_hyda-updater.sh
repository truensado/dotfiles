#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"

icon="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
term="${TERMINAL:-ghostty}"
ofc=0
aur=0

usage() {
  cat <<'EOF'

Hyda-Updater — System Updater

Usage:
 waybar         -w | w  ->  Outputs Waybar Module
 notify         -n | n  ->  Sends Notification About Updates
 default        -d | d  ->  Updates the System Now
EOF
}

get_aur() {
  local helper
  for helper in paru yay; do
    if command -v "$helper" &>/dev/null; then
      aur=$("$helper" -Qua 2>/dev/null | wc -l)
      break
    fi
  done
}

check_top() {
  if ! command -v topgrade &> /dev/null; then
    local action=$(notify-send -u critical -a "HYDA Updater" -r 9996 -i "$icon" -t 5000 "Hyda Updater" "Topgrade not installed" --action="install=Install Now" --action="dismiss=Dismiss")
    if [[ "$action" == "install" ]]; then
      "$term" --class=com.install-topgrade --title=install-topgrade --initial-command="echo -e '${bold}Installing Topgrade${reset}...';\
      sudo pacman -S --noconfirm topgrade && notify-send -e 'Hyda' 'topgrade installed' -i $icon -t 3000\
      || notify-send -e -u critical 'Hyda' 'tograde failled to install' -i $icon -t 3000"
    fi
  fi
}

updates_way() {
  local total=$((ofc + aur))
  if (( total > 0 )); then
    echo "{\"text\":\" $total\",\"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur\"}"
  else
    echo "{\"text\":\"\", \"tooltip\":\" Packages are up to date\"}"
  fi
}

updates_not() {
  local title msg
  if (( ofc > 0 && aur > 0 )); then
    title="Updates Available"; msg="System: $ofc\nAUR: $aur"
  elif (( ofc > 0 )); then
    title="System Updates Available"; msg="System: $ofc"
  elif (( aur > 0 )); then
    title="AUR Updates Available"; msg="AUR: $aur"
  else
    echo "No updates available."; exit 0
  fi

  local action=$(notify-send "$title" "$msg" -i "$icon" -t "5000" --action="update=Update Now" --action="dismiss=Dismiss" 2>/dev/null)
  [[ "$action" == "update" ]] && update_now
}

update_now() {
  "$term" --class=com.systemupdate --title="systemupdate" \
  --initial-command="echo -e '${bold}Starting updates${reset}...'; \
    topgrade --skip-notify --only system && \
    notify-send '✅ System Update Complete' -i '$icon' -e -t 3500 || \
    notify-send -u critical 'Hyda' 'failed to update system' -i $icon -t 3500"
}

main() {
  ofc=$(checkupdates 2>/dev/null | wc -l)
  get_aur
  check_top
}

case "$1" in
  waybar | -w | w)
    main
    updates_way
    ;;
  notify | -n | n)
    main
    updates_not
    ;;
  default | -d | d)
    main
    (( ofc > 0 || aur > 0 )) && update_now
    ;;
  *)
    usage
    ;;
esac
