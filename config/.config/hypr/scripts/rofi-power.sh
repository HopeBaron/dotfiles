#!/usr/bin/env bash
# Power menu, rendered through rofi so it matches the launcher.
set -euo pipefail

# Only offer Lock once a lockscreen is actually installed.
entries=()
command -v hyprlock >/dev/null && entries+=("󰌾  Lock")
entries+=("󰤄  Suspend" "󰗽  Log out" "󰜉  Reboot" "󰐥  Shut down")

choice=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "Power" -theme-str 'window { width: 320px; } listview { lines: 5; }')

case "${choice:-}" in
  *Lock)        hyprlock ;;
  *Suspend)     systemctl suspend ;;
  *"Log out")   hyprctl dispatch 'hl.dsp.exit()' ;;
  *Reboot)      systemctl reboot ;;
  *"Shut down") systemctl poweroff ;;
  *) exit 0 ;;
esac
