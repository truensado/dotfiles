#!/usr/bin/env bash
# description: cli tool to copy screenshots of minecraft instance

$ss_path="${XDG_PICTURES_DIR:-$HOME/Pictures}/screenshots"

mkdir -p "$ss_path"

cp -r "$INST_MC_DIR/screenshots/." "$ss_path"
