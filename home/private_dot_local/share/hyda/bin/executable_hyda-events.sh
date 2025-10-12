#!/usr/bin/env bash
# description: daemon for dynamic hyprland behavior

scroll_mode=""
kbd_state=""
cur_cursor=""

kID=$(xinput list --id-only "xwayland-keyboard:1" 2>/dev/null)

handle() {
  case "$1" in
    activewindow* | activewindowv2*)
      local tag=$(hyprctl -j activewindow | jq -r '.tags? // [] | join(" ")' 2>/dev/null)
      local cursor="$(gsettings get org.gnome.desktop.interface cursor-theme | sed -E 's/^[^A-Za-z]+//; s/[^A-Za-z]+$//') $(gsettings get org.gnome.desktop.interface cursor-size)"

      # ---- scroll method change
      if [[ "$tag" == *game* ]]; then
        new_scroll="no_scroll"
      else
        new_scroll="on_button_down"
      fi

      if [[ "$new_scroll" != "$scroll_mode" ]]; then
        hyprctl keyword input:scroll_method "$new_scroll" &> /dev/null
        scroll_mode="$new_scroll"
        log_info "Scroll mode changed to: $new_scroll"
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
        log_info "Keyboard ${new_kbd}d for xwayland-keyboard:1"
      fi

      # ---- change cursor dynamically
      if [[ "$cursor" != "$cur_cursor" ]]; then
        hyprctl setcursor "$cursor" &> /dev/null
        cur_cursor="$cursor"
        log_info "Cursor updated to: $cursor"
      fi
      ;;
  esac
}

main() {
  log_info "Hyda Event Daemon Started"
  socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | while read -r line; do handle "$line"; done
}

if [[ $# -gt 0 ]]; then
  log_error "hyda events daemon doesn't take arguments — just run it as is"
  exit 1
else
  main
fi
