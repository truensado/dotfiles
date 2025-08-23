#!/usr/bin/env bash

set -e

ERROR="\e[31m"
SUCCESS="\e[32m"
WARNING="\e[33m"
RESET="\e[0m"
BOLD="\e[1m"

chaotic_key=3056513887B78AEB
chaotic_full=EF925EA60F33D0CB85C44AD13056513887B78AEB
file_path=/etc/pacman.conf

grep -q "chaotic-aur" "$file_path" && exit 0

write_chaotic() {
  
  echo -e "${BOLD}backing up pacman.conf${RESET}"
  
  sudo cp "$file_path" "$file_path.bak.$(date +%s)"
  
  printf "\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n" | sudo tee -a /etc/pacman.conf >/dev/null

}

clean_chaotic() {
  
  echo -e "${BOLD}cleaning up chaotic entries${RESET}"
  
  sudo pacman-key --list-keys "$chaotic_key" &> /dev/null && sudo pacman-key --delete "$chaotic_full" || true
  
  pacman -Qq chaotic-keyring &> /dev/null && sudo pacman -Rns --noconfirm chaotic-keyring || true
  
  pacman -Qq chaotic-mirrorlist &> /dev/null && sudo pacman -Rns --noconfirm chaotic-mirrorlist || true

  sudo sed -i '/chaotic-aur/d' "$file_path" || true
  sudo sed -i '/chaotic-mirrorlist/d' "$file_path" || true
  
  sudo pacman -Sy

}

install_chaotic() {
  
  trap 'chaotic_error' ERR

  echo -e "${BOLD}installing chaotic aur${RESET}"

  sudo pacman-key --recv-key "$chaotic_key" --keyserver keyserver.ubuntu.com
  
  sudo pacman-key --lsign-key "$chaotic_key"

  sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'

  sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

  write_chaotic

  sudo pacman -Sy

  echo -e "${SUCCESS}installed chaotic aur successfully${RESET}"
  
  exit 0

}

chaotic_error() {
  
  tput setaf 1
  
  echo -e "${ERROR}ERROR${RESET}: ${BOLD}install failed, reverting${RESET}..."
  
  tput sgr0
  
  clean_chaotic
  
  echo -e "${SUCCESS}revert successful${RESET}"
  
  exit 1
}

command -v pacman &> /dev/null || { echo -e "${ERROR}pacman not found${RESET}"; exit 1; }

install_chaotic
