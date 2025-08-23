#!/usr/bin/env bash

set -e

chaotic_key=3056513887B78AEB
chaotic_full=EF925EA60F33D0CB85C44AD13056513887B78AEB
file_path=/etc/pacman.conf

grep -q "chaotic-aur" "$file_path" && exit 0

write_chaotic() {
  
  echo "backing up pacman.conf"
  
  sudo cp "$file_path" "$file_path.bak.$(date +%s)"
  
  printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.conf >/dev/null

}

clean_chaotic() {
  
  echo "cleaning up chaotic entries"
  
  sudo pacman-key --list-keys "$chaotic_key" &> /dev/null && sudo pacman-key --delete "$chaotic_full" || true
  
  pacman -Qq chaotic-keyring &> /dev/null && sudo pacman -Rns --noconfirm chaotic-keyring || true
  
  pacman -Qq chaotic-mirrorlist &> /dev/null && sudo pacman -Rns --noconfirm chaotic-mirrorlist || true

  sudo sed -i '/chaotic-aur/d' "$file_path" || true
  sudo sed -i '/chaotic-mirrorlist/d' "$file_path" || true
  
  sudo pacman -Sy

}

install_chaotic() {
  
  trap 'chaotic_error' ERR

  echo "installing chaotic aur"

  sudo pacman-key --recv-key "$chaotic_key" --keyserver keyserver.ubuntu.com
  
  sudo pacman-key --lsign-key "$chaotic_key"

  sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'

  sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

  write_chaotic

  sudo pacman -Sy

  echo "installed chaotic aur successfully"
  
  exit 0

}

chaotic_error() {
  
  tput setaf 1
  
  echo "ERROR: install failed, reverting..."
  
  tput sgr0
  
  clean_chaotic
  
  echo "revert successful"
  
  exit 1
}

command -v pacman &> /dev/null || { echo "pacman not found"; exit 1; }

install_chaotic
