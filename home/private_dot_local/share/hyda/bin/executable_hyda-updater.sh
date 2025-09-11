#!/usr/bin/env bash

scrDir=$(dirname "$(realpath "$0")")
source "$scrDir/hyda-variables.sh"

icon="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
ofc="$(checkupdates 2>/dev/null | wc -l)"

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
  local aur_hlpr
  if command -v paru &>/dev/null; then
    aur_hlpr="paru"
  elif command -v yay &>/dev/null; then
    aur_hlpr="yay"
  fi
  
  if [[ -v aur_hlpr ]]; then
    aur=$($aur_hlpr -Qua | wc -l)
  fi
}

notify_send() {
  local title="$1"
  local msg="$2"
  local time="${3:-3000}"

  notify-send "$title" "$msg" -i "$icon" -t "$time" "${@:4}"
}

check_dependencies() {
  if ! command -v topgrade &> /dev/null; then
    local action=$(notify_send "Hyda" "Topgrade not installed" 5000 -u critical --action="install=Install Now" --action="dismiss=Dismiss")
    [[ "$action" == "install" ]] && \
    $TERMINAL --title=install-topgrade\
    --initial-command="echo -e '${bold}Installing Topgrade${reset}...';\
    sudo pacman -S --noconfirm topgrade && notify-send 'Hyda' 'topgrade installed' -i $icon -t 5000\
    || notify-send -u critical 'Hyda' 'failed to install topgrade' -i $icon -t 5000"
  fi
}

check_updates_waybar() {
  local total=$(( ofc + aur ))
  if ! (( total == 0 )); then
    echo "{\"text\":\" $total\",\"tooltip\":\"󱓽 Official $ofc\n󱓾 AUR $aur\"}"
  else
    echo "{\"text\":\"\", \"tooltip\":\" Packages are up to date\"}"
  fi
}

check_updates_notify() {
  local title msg
  if (( ofc > 0 && aur > 0 )); then
    title="Updates Available"
    msg="System: $ofc\nAUR: $aur"
  elif (( ofc > 0 )); then
    title="System Updates Available"
    msg="System: $ofc"
  elif (( aur > 0 )); then
    title="AUR Updates Available"
    msg="AUR: $aur"
  else
    echo "No updates available."
    exit 0
  fi

  local action=$(notify_send "$title" "$msg" 5000 --action="update=Update Now" --action="dismiss=Dismiss" 2>/dev/null)
  if [[ "$action" == "update" ]]; then
    $TERMINAL --title=systemupdate\
    --initial-command="echo -e '{$bold}Starting updates${reset}...';\
    topgrade --skip-notify --only system && notify-send '✅ System Update Complete' -i '$icon' -e -t 3500\
    || notify-send -u critical 'Hyda' 'failed to update system' -i $icon -t 3500"
  else
    exit 0
  fi
}

update_now() {
  if (( ofc > 0 || aur > 0 )); then
    $TERMINAL --title=systemupdate\
    --initial-command="echo -e '{$bold}Starting updates${reset}...';\
    topgrade --skip-notify --only system && notify-send '✅ System Update Complete' -i '$icon' -e -t 3500\
    || notify-send -u critical 'Hyda' 'failed to update system' -i $icon -t 3500"
  fi
}

main() {
  get_aur
  check_dependencies
}

case $1 in
  waybar | w | -w)
    main
    check_updates_waybar
    ;;
  notify | n | -n)
    main
    check_updates_notify
    ;;
  default | d | -d)
    main
    update_now
    ;;
  *)
    usage
    ;;
esac
