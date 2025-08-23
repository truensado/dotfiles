#!/usr/bin/env bash

do_nextcloud() {
  if command -v nextcloud &> /dev/null; then
    
    local path="${XDG_CONFIG_HOME:-$HOME/.config}/Nextcloud/nextcloud.cfg"
    local value="showMainDialogAsNormalWindow=true"
    
    mkdir -p "$(dirname "$path")"
    
    if [ ! -f "$path" ]; then
      printf "[General]\n%s=%s\n" "$value" >"$path"
    elif ! grep -q "^${value}\$" "$path"; then
      if grep -q "^\[General\]" "$path"; then
        sed -i "/\[General\]/a $value" "$path"
      else
        printf "\n[General]\n%s\n" "$value" >> "$path"
      fi
    fi

  fi
}

do_yazi() {
  if command -v ya &> /dev/null; then
    ya pkg install && ya pkg upgrade
  fi
}

do_nextcloud
do_yazi
