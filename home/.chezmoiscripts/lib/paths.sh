#!/usr/bin/env bash

# ---- General
pacConf="/etc/pacman.conf"

# ---- udevs
udevPath="/etc/udev/rules.d"
udevSnack="$udevPath/99-snackbox-controllers.rules"
udevDualctl="$udevPath/98-dualsensectl.rules"
udevDs5="$udevPath/99-ignore-ds5-touchpad.rules"
udevVia="$udevPath/92-viia.rules"
