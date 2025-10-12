#!/usr/bin/env bash
# description: toggle hyprland game mode

do_notify() {
  local state="$1"
  notify-send -e "GameMode" "<b><big>$state</big></b>" -a "HYDA" -r 9991 -i "applications-games-symbolic" -h string:synchronous:gamemode
}

get_state() {
  hyprctl getoption animations:enabled 2>/dev/null | awk 'NR==1 {print $2}'
}

enable_gamemode() {
  hyprctl -q --batch "
    keyword animations:enabled 0;
    keyword decoration:shadow:enabled 0;
    keyword decoration:blur:xray 1;
    keyword decoration:blur:enabled 0;
    keyword general:gaps_in 0;
    keyword general:gaps_out 0;
    keyword general:border_size 1;
    keyword decoration:rounding 0 ;
    keyword decoration:active_opacity 1 ;
    keyword decoration:inactive_opacity 1 ;
    keyword decoration:fullscreen_opacity 1 ;
    keyword layerrule noanim,waybar ;
    keyword layerrule noanim,swaync-notification-window ;
    keyword layerrule noanim,swww-daemon ;
    keyword layerrule noanim,rofi;
    keyword windowrule opaque,class:(.*);
  " || log_error "Failed to apply Game Mode settings"
  
  do_notify "On"
  log_success "Game Mode enabled"
}

disable_gamemode() {
  hyprctl reload config-only -q || log_error "Failed to reload Hyprland config"
  do_notify "Off"
  log_info "Game Mode disabled"
}

main() {
  local state=$(get_state)

  if [[ "$state" == "1" ]]; then
    enable_gamemode
  else
    disable_gamemode
  fi
}

if [[ $# -gt 0 ]]; then
  log_error "hyda gamemode doesn't require arguments — just run it as is"
  exit 1
else
  main
fi
