#!/usr/bin/env bash
# description: cli tool to copy screenshots of minecraft instance

mkdir -p "$HOME/Pictures/screenshots"

cp -r "$INST_MC_DIR/screenshots/." "$HOME/Pictures/screenshots"
