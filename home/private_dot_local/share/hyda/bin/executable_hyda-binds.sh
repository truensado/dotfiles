#!/usr/bin/env bash

get_binds() {
hyprctl -j binds |
jq -r '
  def hasbit(m; b): (((m / b) | floor) % 2) == 1;
  def mods(m):
    [
      (if hasbit(m;64) then "SUPER" else empty end),
      (if hasbit(m;4)  then "CTRL"  else empty end),
      (if hasbit(m;8)  then "ALT"   else empty end),
      (if hasbit(m;1)  then "SHIFT" else empty end)
    ] | join(" + ");

  def btn(c): {
    "272":"MOUSE_LEFT","273":"MOUSE_RIGHT","274":"MOUSE_MIDDLE",
    "275":"MOUSE_SIDE","276":"MOUSE_EXTRA","277":"MOUSE_FORWARD","278":"MOUSE_BACK"
  }[c] // c;

  def keyname(k):
    if k|startswith("mouse:") then
      btn(k|split(":")[1])
    elif k|startswith("mouse_") then
      k | ascii_upcase
    else
      k
    end;

  def clean(s): (s // "")
    | gsub("uwsm([[:space:]]+app)?([[:space:]]+-s[[:space:]]+b)?([[:space:]]+--)?[[:space:]]*"; " ")
    | gsub("ghostty[[:space:]]+--class=[^[:space:]]+[[:space:]]+-e[[:space:]]+"; "")
    | gsub("wpctl[[:space:]]+set-volume[[:space:]]+"; "")
    | gsub("(^|[[:space:]])-[[:alpha:]][^[:space:]]*"; "")
    | gsub("systemctl[[:space:]]+--user[[:space:]]"; "")
    | gsub("wpctl[[:space:]]+set-mute"; "mute")
    | gsub("@DEFAULT(_AUDIO)?_SOURCE@"; "mic")
    | gsub("@DEFAULT(_AUDIO)?_SINK@"; "output")
    | gsub("hyprctl[[:space:]]+kill"; "killsession")
    | gsub("hydacli[[:space:]]+"; "")
    | gsub("brightnessctl[[:space:]]+"; "brightness")
    | gsub("hyprctl[[:space:]]+hyprsunset[[:space:]]+gamma"; "brightness")
    | gsub("(^|[[:space:]])audio($|[[:space:]])"; " switch-audio ")
    | gsub("[[:space:]]+toggle"; "")
    | gsub("steam-[^[:space:]]+"; "steam")
    | gsub("pkill[[:space:]]+rofi[[:space:]]*\\|\\|[[:space:]]*rofi.*"; "rofi")
    | gsub("exec[[:space:]]*"; " ")
    | gsub("^[[:space:]]*'\''|'\''[[:space:]]*$"; "")
    | gsub("[[:space:]]+"; " ")
    | gsub("^[[:space:]]+|[[:space:]]+$"; "");

  .[] |
  (mods(.modmask)) as $mods |
  (keyname(.key)) as $key |
  (clean(.dispatcher)) as $d |
  (clean(.arg)) as $a |
  "\($mods)\(if $mods != "" then " + " else "" end)\($key) -> \([ $d, $a ] | map(select(. != "")) | join(" "))"
'

}

parse_bindings() {
awk '
{
    # split into key combo and action
    split($0, parts, " -> ")
    first = parts[1]
    second = parts[2]

    # trim spaces
    gsub(/^[ \t]+|[ \t]+$/, "", first)
    gsub(/^[ \t]+|[ \t]+$/, "", second)

    # normalize around plus signs (so SUPER+ALT+1 == "SUPER + ALT + 1")
    gsub(/[ \t]*\+[ \t]*/, " + ", first)

    # store for later so we can align properly
    combos[NR] = first
    actions[NR] = second
    if (length(first) > maxlen) maxlen = length(first)

    # ONE matcher handles all three:
    #   SUPER + <digit>                  -> workspace N
    #   SUPER + ALT + <digit>            -> movetoworkspacesilent N
    #   SUPER + SHIFT + <digit>          -> movetoworkspace N
    is_bind = match(first, /^SUPER( \+ (ALT|SHIFT))? \+ ([0-9])$/, m)
    is_act  = match(second, /^(workspace|movetoworkspacesilent|movetoworkspace)[ \t,]+([0-9]+)$/, n)

    if (is_bind && is_act) {
        mod = m[2]            # "", ALT, or SHIFT (when group missing, m[2] is empty)
        d   = m[3] + 0        # digit 0..9
        w   = n[2] + 0        # workspace number
        act = n[1]

        if (mod == "" && act == "workspace") {
            cand[NR] = 1; present[d] = 1; wnum[d] = w
            if (firstIndex == 0) firstIndex = NR
        } else if (mod == "ALT" && act == "movetoworkspacesilent") {
            cand_alt[NR] = 1; present_alt[d] = 1; wnum_alt[d] = w
            if (firstIndex_alt == 0) firstIndex_alt = NR
        } else if (mod == "SHIFT" && act == "movetoworkspace") {
            cand_shift[NR] = 1; present_shift[d] = 1; wnum_shift[d] = w
            if (firstIndex_shift == 0) firstIndex_shift = NR
        }
    }
}
END {
    # validate sets
    ok = 1
    for (d=1; d<=9; d++) if (!present[d] || wnum[d] != d) ok = 0
    has0 = (present[0] && wnum[0] == 10)

    ok_alt = 1
    for (d=1; d<=9; d++) if (!present_alt[d] || wnum_alt[d] != d) ok_alt = 0
    has0_alt = (present_alt[0] && wnum_alt[0] == 10)

    ok_shift = 1
    for (d=1; d<=9; d++) if (!present_shift[d] || wnum_shift[d] != d) ok_shift = 0
    has0_shift = (present_shift[0] && wnum_shift[0] == 10)

    if (ok) {
        coll_first  = has0 ? "SUPER + 0-9" : "SUPER + 1-9"
        coll_second = has0 ? "workspace 1-10" : "workspace 1-9"
        if (length(coll_first) > maxlen) maxlen = length(coll_first)
    }
    if (ok_alt) {
        coll_first_alt  = has0_alt ? "SUPER + ALT + 0-9" : "SUPER + ALT + 1-9"
        coll_second_alt = has0_alt ? "movetoworkspacesilent 1-10" : "movetoworkspacesilent 1-9"
        if (length(coll_first_alt) > maxlen) maxlen = length(coll_first_alt)
    }
    if (ok_shift) {
        coll_first_shift  = has0_shift ? "SUPER + SHIFT + 0-9" : "SUPER + SHIFT + 1-9"
        coll_second_shift = has0_shift ? "movetoworkspace 1-10" : "movetoworkspace 1-9"
        if (length(coll_first_shift) > maxlen) maxlen = length(coll_first_shift)
    }

    for (i = 1; i <= NR; i++) {
        if (ok && i == firstIndex) {
            printf "%-*s     ->     %s\n", maxlen, coll_first, coll_second; continue
        }
        if (ok_alt && i == firstIndex_alt) {
            printf "%-*s     ->     %s\n", maxlen, coll_first_alt, coll_second_alt; continue
        }
        if (ok_shift && i == firstIndex_shift) {
            printf "%-*s     ->     %s\n", maxlen, coll_first_shift, coll_second_shift; continue
        }
        if (ok && cand[i]) continue
        if (ok_alt && cand_alt[i]) continue
        if (ok_shift && cand_shift[i]) continue
        printf "%-*s     ->     %s\n", maxlen, combos[i], actions[i]
    }
}'
}

get_binds | sort -u | parse_bindings |  rofi -dmenu -i -p 'Keybinds' -theme ~/.config/rofi/configs/keybinds.rasi -kb-accept-entry "" -kb-accept-custom "" -me-accept-entry ""
