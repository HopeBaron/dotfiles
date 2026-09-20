#!/usr/bin/env bash
# Clipboard history picker: choose a past entry and put it back on the clipboard.
#
# History is recorded by the `wl-paste --watch cliphist store` processes started
# from hyprland.lua; this script only reads it.
set -euo pipefail

# cliphist list emits "<id>\t<preview>"; decode takes that whole line back.
choice=$(cliphist list | wofi --show dmenu --prompt "Clipboard" \
           --width 50% --height 50% --cache-file /dev/null) || exit 0

# Escaping wofi yields an empty selection -- bail out rather than blanking the
# clipboard by piping nothing into wl-copy.
[ -z "$choice" ] && exit 0

printf '%s' "$choice" | cliphist decode | wl-copy
