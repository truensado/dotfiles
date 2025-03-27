#!/usr/bin/env bash
set -euo pipefail

# -------------------------
# 🔧 Init
ICON="$(awk -F= '/^ID=/{print $2}' /etc/os-release)"
CHECKUPDATES=$(checkupdates 2>/dev/null | wc -l)
AUR=0

# -------------------------
# 🔍 Check AUR Helper
if command -v paru &>/dev/null; then
  AUR=$(paru -Qua | wc -l)
elif command -v yay &>/dev/null; then
  AUR=$(yay -Qua | wc -l)
else
  echo "No AUR helper available..." >&2
fi

# -------------------------
# ⚙️ Perform update in terminal
perform_update() {
  kitty --title systemupdate sh -c \
    "echo 'Starting updates...'; topgrade --skip-notify --only system; notify-send '✅ System Update Complete' -i '$ICON' -e -t 3500"
}

# -------------------------
# 🧱 Ensure topgrade is installed
ensure_topgrade() {
  if ! command -v topgrade &>/dev/null; then
    if [ ! -f /tmp/topgrade_check.txt ]; then
      action=$(notify-send "Topgrade Not Installed" "Would you like to install it?" -i "$ICON" -e -t 5000 \
        --action="download=Install Now" --action="dismiss=Dismiss")
      case "$action" in
        download)
          if command -v paru &>/dev/null; then
            paru -S --noconfirm topgrade
          elif command -v yay &>/dev/null; then
            yay -S --noconfirm topgrade
          else
            echo "Installing paru (no helper found)" >&2
            kitty --title install-paru sh -c "sudo pacman -S --noconfirm paru"
            paru -S --noconfirm topgrade
          fi
          ;;
        *)
          touch /tmp/topgrade_check.txt
          exit 1
          ;;
      esac
    else
      echo "Topgrade previously dismissed." >&2
      exit 1
    fi
  fi
}

# -------------------------
# 🚨 Prompt user if updates exist
prompt_updates() {
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

  action=$(notify-send "$title" "$msg" -i "$ICON" -t 7500 \
    --action="update=Update Now" --action="dismiss=Dismiss")
  [[ "$action" == "update" ]] && perform_update || exit 1
}

# -------------------------
# 🧠 Main
ensure_topgrade
prompt_updates
