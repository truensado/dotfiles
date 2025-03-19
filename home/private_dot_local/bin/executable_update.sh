#!/usr/bin/env bash
# Script to check for updates and send a notification
# -------------------------
ICON=$(awk -F= '/^ID=/{print $2}' /etc/os-release)
CHECKUPDATES=$(checkupdates 2>/dev/null | wc -l)
# -------------------------
# Check if a package manager is available and use the correct command
if command -v  paru &>/dev/null; then
  AUR=$(paru -Qua | wc -l)
elif command -v yay &>/dev/null; then
  AUR=$(yay -Qua | wc - l)
else 
  AUR=""
  echo "No aur helper available..."
fi
# perform update code block
perform_update() {
  kitty --title systemupdate sh -c "echo 'Starting updates...'; topgrade --skip-notify --only system; notify-send 'System Update Complete' -i $ICON -e -t 3500"
}
# check for topgrade 
if ! command -v topgrade &>/dev/null; then
  if [ ! -f /tmp/topgrade_check.txt ]; then
    action=$(notify-send "Topgrade not installed" "would you like to install it?" -i $ICON -e -t 5000 --action="download=Install Now" --action="Dismiss")
    case "$action" in 
      download)
        if command -v paru &> /dev/null; then
          paru -S --noconfirm topgrade
        elif command -v yay &> /dev/null; then
          yay -S --noconfirm topgrade
        else
          echo "No Aur helper installed...installing paru"
          kitty --title install-paru sh -c "echo 'Paru not found; Installing...'; sudo pacman -S --noconfirm paru"
        fi 
        ;;
      *)
        touch /tmp/topgrade_check.txt && exit 1
        ;;
    esac
  else 
    echo "Topgrade dismissed" && exit 1
  fi 
fi
# -------------------------
# If no updates are available, exit
if [ "$CHECKUPDATES" -gt 0 ] && [ "$AUR" -gt 0 ]; then
  action=$(notify-send "Updates Available" "System: $CHECKUPDATES\nAur: $AUR" -i $ICON -t 7500 --action="update=Update Now" --action="Dismiss")
  case "$action" in 
    update) perform_update ;;
    *) exit 1 ;;
  esac
elif [ "$CHECKUPDATES" -gt 0 ]; then 
  action=$(notify-send "System Updates Available" "System: $CHECKUPDATES" -i $ICON -t 7500 --action="update=Update Now" --action="Dismiss")
  case "$action" in 
    update) perform_update ;;
    *) exit 1 ;;
  esac
elif [ -n "$AUR" -gt 0 ]; then
  action=$(notify-send "Updates Available" "Aur: $AUR" -i $ICON -t 7500 --action="update=Update Now" --action="Dismiss")
  case "$action" in 
    update) perform_update ;;
    *) exit 1 ;;
  esac
else 
  echo "No updates available..." && exit 0
fi 
