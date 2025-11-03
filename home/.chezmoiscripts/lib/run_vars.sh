#!/usr/bin/env bash

# ---- colors

error=$'\e[31m'
success=$'\e[32m'
warning=$'\e[33m'
info=$'\e[36m'
reset=$'\e[0m'
bold=$'\e[1m'

# ---- icons

isuccess="[✔]"
ierror="[✖]"
iwarning="[!]"
iinfo="[i]"

# ---- logs

log_success() { echo -e "${success}${isuccess}${reset} ${bold}$*${reset}" >&2; }
log_warning() { echo -e "${warning}${iwarning}${reset} ${bold}$*${reset}" >&2; }
log_error() { echo -e "${error}${ierror}${reset} ${bold}$*${reset}" >&2; }
log_info() { echo -e "${info}${iinfo}${reset} ${bold}$*${reset}" >&2; }
