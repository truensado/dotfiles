#!/usr/bin/env bash

scroll_mode=""
kbd_state=""

kID=$(xinput list --id-only "xwayland-keyboard:1" 2>/dev/null)

# Define event handler
handle() {
  case "$1" in
    activewindow* | activewindowv2*)
      local tag=$(hyprctl -j activewindow | jq -r '.tags? // [] | join(" ")' 2>/dev/null)

      # ---- scroll method change
      if [[ "$tag" == *game* ]]; then
        new_scroll="no_scroll"
      else
        new_scroll="on_button_down"
      fi

      if [[ "$new_scroll" != "$scroll_mode" ]]; then
        hyprctl keyword input:scroll_method "$new_scroll" &> /dev/null
        scroll_mode="$new_scroll"
      fi

      # ---- prevent fighting games from reading keyboard as player 2
      if [[ "$tag" == *fighter* ]]; then
        new_kbd="disable"
      else
        new_kbd="enable"
      fi

      if [[ "$new_kbd" != "$kbd_state" && -n "$kID" ]]; then
        xinput "$new_kbd" "$kID" &> /dev/null
        kbd_state="$new_kbd"
      fi
      ;;
  esac
}


socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
