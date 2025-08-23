#!/usr/bin/env bash

set -eu

current_1=""
current_2=""

handle() {
  case "$1" in
    activewindow*|activewindowv2*)
      class=$(hyprctl -j activewindow | jq -r '.class' 2>/dev/null || echo "")
      title=$(hyprctl -j activewindow | jq -r '.title' 2>/dev/null || echo "")
      
      # scroll method change
      if [[ "$class" =~ ^steam_app_[0-9]+$ ]]; then
        desired_1="no_scroll"
      else
        desired_1="on_button_down"
      fi
      
      if [ "$desired_1" != "$current_1" ]; then
        hyprctl keyword input:scroll_method "$desired_1" >/dev/null 2>&1
        current_1="$desired_1"
      fi
      
      # prevent fighting games from reading keyboard as player 2
      if [[ "$class" =~ ^steam_app_[0-9]+$ ]] && [[ "$title" =~ Guilty\ Gear\ -Strive- || "$title" =~ Street\ Fighter\ 6 ]]; then
        desired_2="disable"
      else
        desired_2="enable"
      fi

      if [[ "$desired_2" != "$current_2" ]]; then
        kbdID="$(xinput list --id-only "xwayland-keyboard:1" 2>/dev/null)"
        xinput "$desired_2" "$kbdID" >/dev/null 2>&1
        current_2="$desired_2"
      fi
 
      ;;
  esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
