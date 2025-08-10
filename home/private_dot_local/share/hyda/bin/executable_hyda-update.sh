#!/usr/bin/env bash

set -e

# ---- Variables ----

ICON="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
CHECKUPDATES=$(checkupdates 2>/dev/null | wc -l)
AUR=0

# ---- Functions ----

check_aur_helper() {
  if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
  elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
  fi
  
  if [[ -v AUR_HELPER ]]; then
    AUR=$($AUR_HELPER -Qua | wc -l)
  fi
}

check_topgrade() {
  if ! command -v topgrade &>/dev/null; then
    if ! $AUR_HELPER -S --noconfirm topgrade; then
      echo "No helper found...Installing paru" >&2
      sudo pacman -S --noconfirm paru
      paru -S --noconfirm topgrade
    else
      echo "Couldn't install topgrade" >&2
      exit 1
    fi
  fi
}

check_updates() {
  local title msg action
  if (( CHECKUPDATES > 0 && AUR > 0 )); then
    title="Updates Available"
    msg="System: $CHECKUPDATES\nAUR: $AUR"
  elif (( CHECKUPDATES > 0 )); then
    title="System Updates Available"
    msg="System: $CHECKUPDATES"
  elif (( AUR > 0 )); then
    title="AUR Updates Available"
    msg="AUR: $AUR"
  else
    echo "No updates available."
    exit 0
  fi

  action=$(notify-send "$title" "$msg" -i "$ICON" -t 7500 --action="update=Update Now" --action="dismiss=Dismiss")
  [[ "$action" == "update" ]] && $TERMINAL --title=systemupdate --initial-command="echo 'Starting updates...'; topgrade --skip-notify --only system; notify-send '✅ System Update Complete' -i '$ICON' -e -t 3500" || exit 1
}

# ---- Main ----

check_aur_helper
check_topgrade
check_updates
