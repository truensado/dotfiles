#!/usr/bin/env bash

# ---- Globals

COMMAND="${1-}"
SUBCOMMAND="${2-}"

THEMES="${XDG_DATA_HOME:-$HOME/.local/share}/hyda/hyda-themes"
HYPR_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
HYPR_THEME_FILE="theme.conf"
META_FILENAME="metadata.json"

GSET="gsettings set org.gnome.desktop.interface"

# ---- Help
usage() {
  cat <<'EOF'
hyde-theme.sh — manage and apply Hyprland themes

Usage:
 hyde-theme.sh                  # Shows options
 hyde-theme.sh list             # list available themes
 hyde-theme.sh rofi             # launch with rofi
 hyde-theme.sh <theme>          # Provides theme data
 hyde-theme.sh <theme> apply    # apply theme

EOF
}

check_packages() {
  for pkg in jq rofi-wayland hyprpaper; do
    if ! command -v "${pkg%%-*}" >/dev/null 2>&1; then
      echo "Installing $pkg..."
      sudo pacman -S --needed "$pkg"
    fi
  done
}

# ---- Notify
NOTIFY() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send \
      --app-name="Hypr Themes" \
      --urgency=low \
      --hint=string:category:system \
      --hint=int:transient:1 \
      --icon="$HOME/.local/share/hyprthemes/theme-icon.png" \
      "🎨 Hypr Theme" "$1"
  fi
}

# ---- List
list_themes() {
  if [[ ! -d "$THEMES" ]]; then
    echo "Theme directory $THEMES does not exist"
    return 0
  fi
  shopt -s nullglob
  local dirs=("$THEMES"/*)
  shopt -u nullglob
  local any=0
  for d in "${dirs[@]}"; do
    [[ -d "$d" ]] || continue
    echo "$(basename "$d")"
    any=1
  done
  (( any == 1 )) || echo "no themes"
}

# ---- Rofi Theme Picker
pick_theme_menu() {
  [[ -d "$THEMES" ]] || { echo "No themes to select."; return 0; }

  local ICON_PX=256       # preview size
  local PAD_PX=16         # listview padding per side
  local SPACE_PX=16       # gap between items
  local MAX_COLS=10       # hard limit

  # focused monitor width (fallback 1920)
  local MON_W
  if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    MON_W="$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused==true) | .width')"
  fi
  [[ "$MON_W" =~ ^[0-9]+$ ]] || MON_W=1920

  # cap the window width (e.g., 70% of monitor or max 1400 px)
  local MAX_W=$(( MON_W * 70 / 100 ))
  (( MAX_W > 1400 )) && MAX_W=1400
  (( MAX_W < 640 )) && MAX_W=640   # don't get too tiny

  # find largest columns that fit within MAX_W
  local cols c need_w
  for (( c=MAX_COLS; c>=1; c-- )); do
    need_w=$(( 2*PAD_PX + c*ICON_PX + (c-1)*SPACE_PX ))
    if (( need_w <= MAX_W )); then cols=$c; break; fi
  done
  : "${cols:=1}"
  need_w=$(( 2*PAD_PX + cols*ICON_PX + (cols-1)*SPACE_PX ))  # final window width

  generate_rows() {
    shopt -s nullglob
    local d name icon cand
    for d in "$THEMES"/*; do
      [[ -d "$d" ]] || continue
      name="$(basename "$d")"

      icon=""
      for cand in "$d/preview.png" "$d/preview.jpg" "$d/preview.jpeg" "$d/preview.webp"; do
        [[ -f "$cand" ]] && { icon="$cand"; break; }
      done
      if [[ -z "$icon" ]]; then
        cand="$(find "$d" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | head -n1)"
        [[ -n "$cand" ]] && icon="$cand"
      fi

      if [[ -n "$icon" ]]; then
        printf '%s\0icon\x1f%s\0info\x1f%s\n' "$name" "$icon" "$name"
      else
        printf '%s\0info\x1f%s\n' "$name" "$name"
      fi
    done
    shopt -u nullglob
  }

  local picked
  picked="$(
    generate_rows | rofi -dmenu -show-icons \
      -config ~/.config/rofi/configs/selector.rasi \
      -theme-str "window { width: ${need_w}px; }" \
      -theme-str "listview { columns: ${cols}; fixed-columns: true; padding: ${PAD_PX}px; spacing: ${SPACE_PX}px; }" \
      -theme-str "element-icon { size: ${ICON_PX}px; }" \
      -p 'Select Hyprland Theme'
  )" || true

  [[ -n "$picked" ]] && printf '%s\n' "$picked"
}

# ---- Read Metadata
read_meta_field() {
  # $1 = meta file, $2 = key
  local file="$1" key="$2"
  jq -r --arg k "$key" '.[$k] // empty' "$file"
}

# ---- Apply GTK
apply_gsettings() {
  local meta="$1"
  if command -v gsettings >/dev/null 2>&1; then
    local color icon gtk cursor cursor_size
    color="$(read_meta_field "$meta" "color-scheme")"
    icon="$(read_meta_field "$meta" "icon-theme")"
    gtk="$(read_meta_field "$meta" "gtk-theme")"
    cursor="$(read_meta_field "$meta" "cursor-theme")"
    cursor_size="$(read_meta_field "$meta" "cursor-size")"

    [[ -n "$color" ]] && $GSET color-scheme "$color" || true
    [[ -n "$icon" ]] && $GSET icon-theme "$icon"   || true
    [[ -n "$gtk" ]] && $GSET gtk-theme "$gtk"     || true
    [[ -n "$cursor" ]] && $GSET cursor-theme "$cursor" || true
    [[ -n "$cursor_size" ]] && $GSET cursor-size "$cursor_size" || true
  else
    echo "Note: gsettings not installed; skipping GTK changes."
  fi
}

# ---- Apply QT
apply_kvantum() {
  local meta="$1"
  local qt_theme
  qt_theme="$(read_meta_field "$meta" "qt-theme")"
  if [[ -n "$qt_theme" ]] && command -v kvantummanager >/dev/null 2>&1; then
    kvantummanager --set "$qt_theme" || echo "Warning: kvantummanager failed for '$qt_theme'"
  fi
}

# ---- Apply Hyprland Theme
install_hypr_include() {
  local theme_dir="$1"
  local meta="$2"
  local hypr_include
  hypr_include="$(read_meta_field "$meta" "hypr-include")"
  local src="$theme_dir/$HYPR_THEME_FILE"

  if [[ "$hypr_include" == "true" || "$hypr_include" == "1" ]]; then
    if [[ -f "$src" ]]; then
      cp -f -- "$src" "$HYPR_DIR/$HYPR_THEME_FILE"
      echo "Hypr theme installed at: $HYPR_DIR/$HYPR_THEME_FILE"
      echo "Reminder: ensure your main Hypr config includes it, e.g.:"
      echo "  source = $HYPR_DIR/$HYPR_THEME_FILE"
    else
      echo "Note: hypr-include enabled but '$src' not found; skipping."
    fi
  fi
}

# ---- Wallpaper
apply_wallpapers() {
  local theme_dir="$1"
  local wall_dir="$theme_dir/wallpapers"
  local IMGS=()

  if [[ -d "$wall_dir" ]]; then
    mapfile -d '' IMGS < <(find "$wall_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) -print0)
    [[ ${#IMGS[@]} -gt 0 ]] || { echo "No images in $wall_dir"; return 0; }
  else
    echo "No wallpaper dir: $wall_dir"
    return 0
  fi

  local MONS=()
  if command -v hyprctl >/dev/null 2>&1; then
    mapfile -t MONS < <(hyprctl monitors -j | jq -r '.[].name')
  fi
  [[ ${#MONS[@]} -gt 0 ]] || { echo "No monitors detected; skipping wallpaper assignment."; return 0; }

  mapfile -t SHUFFLED < <(printf '%s\n' "${IMGS[@]}" | shuf)

  if command -v swww >/dev/null 2>&1; then
    if ! pgrep -x swww-daemon >/dev/null 2>&1; then
      setsid uwsm app -- swww-daemon >/dev/null 2>&1 &
    fi

    local TRANSITION_TYPE="any"     
    local TRANSITION_DURATION="0.7"  
    local TRANSITION_FPS="60"
    local RESIZE_MODE="crop"         

    for i in "${!MONS[@]}"; do
      local mon="${MONS[$i]}"
      local img="${SHUFFLED[$(( i % ${#SHUFFLED[@]} ))]}"
      swww img -o "$mon" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-duration "$TRANSITION_DURATION" \
        --transition-fps "$TRANSITION_FPS" \
        --resize "$RESIZE_MODE" \
        "$img" >/dev/null 2>&1 || true
    done
    return 0

  elif command -v hyprpaper >/dev/null 2>&1; then
    if command -v swww >/dev/null 2>&1 && pgrep -x swww-daemon; then
      pkill -x swww-daemon >/dev/null 2>&1 || true
    fi

    for i in "${!MONS[@]}"; do
      local img="${SHUFFLED[$(( i % ${#SHUFFLED[@]} ))]}"
      hyprctl hyprpaper preload "$img" >/dev/null 2>&1 || true
    done
    
    for i in "${!MONS[@]}"; do
      local mon="${MONS[$i]}"
      local img="${SHUFFLED[$(( i % ${#SHUFFLED[@]} ))]}"
      hyprctl hyprpaper wallpaper "$mon,$img" >/dev/null 2>&1 || true
    done
  else
    echo "Warning: neither swww nor hyprpaper available; skipping wallpaper assignment."
  fi
}

# ---- Apply Theme
apply_theme() {
  local theme="$1"
  local theme_path="$THEMES/$theme"
  local meta="$theme_path/$META_FILENAME"

  [[ -d "$theme_path" ]] || { echo "Unknown theme '$theme'"; exit 1; }

  apply_gsettings "$meta"
  apply_kvantum "$meta"
  install_hypr_include "$theme_path" "$meta"
  apply_wallpapers "$theme_path"

  echo "Theme '$theme' applied."
  NOTIFY "Theme $theme applied"
}

# Theme List Help
show_theme_help() {
  local theme="$1"
  local theme_path="$THEMES/$theme"
  local meta="$theme_path/$META_FILENAME"

  if [[ -f "$meta" ]]; then
    local theme_name author desc
    theme_name="$(read_meta_field "$meta" "theme")"
    author="$(read_meta_field "$meta" "author")"
    desc="$(read_meta_field "$meta" "description")"
    echo "Theme: ${theme_name:-$theme}"
    [[ -n "$author" ]] && echo "Author: $author"
    [[ -n "$desc" ]] && echo "Description: $desc"
  else
    echo "No metadata ($META_FILENAME) found for theme '$theme'"
  fi
}

# -------- Main --------
main() {
  local cmd="${1-}" sub="${2-}"
  case "$cmd" in
    ""|-h|--help|help)
      usage
      return 0
      ;;
    rofi)
      local picked
      picked="$(pick_theme_menu)" || true
      [[ -n $picked ]] || return 0
      apply_theme "$picked"
      return $?
      ;;
    list)
      list_themes
      return $?
      ;;
    *)
      # Treat $cmd as a theme name. Bare theme shows description; 'apply' applies it.
      case "${sub-}" in
        "")    show_theme_help "$cmd"; return $? ;;
        apply) apply_theme      "$cmd"; return $? ;;
        *)
          { echo "Unknown subcommand '$sub' for theme '$cmd'"; usage; } >&2
          return 1
          ;;
      esac
      ;;
  esac
}

check_packages
main "$@"
