#!/usr/bin/env bash
# Power menu, rendered through rofi so it matches the launcher.
set -euo pipefail

scripts=$(dirname "$0")
coffee_icon=$'' # same glyph as the waybar module

# Only offer Lock once a lockscreen is actually installed.
entries=()
command -v hyprlock >/dev/null && entries+=("󰌾  Lock")
if [[ -x "$scripts/caffeine.sh" ]]; then
  caffeine_state="Off"
  "$scripts/caffeine.sh" status | grep -q '"class":"active"' && caffeine_state="On"
  entries+=("$coffee_icon  Caffeine: $caffeine_state")
fi
entries+=("󰤄  Suspend" "󰗽  Log out" "󰜉  Reboot" "󰐥  Shut down")

choice=$(printf '%s\n' "${entries[@]}" | rofi -dmenu -i -p "Power" -theme-str 'window { width: 320px; } listview { lines: 6; }')

case "${choice:-}" in
  *Lock)        hyprlock ;;
  *Caffeine*)   "$scripts/caffeine.sh" toggle ;;
  *Suspend)     systemctl suspend ;;
  *"Log out")   hyprctl dispatch 'hl.dsp.exit()' ;;
  *Reboot)      systemctl reboot ;;
  *"Shut down") systemctl poweroff ;;
  *) exit 0 ;;
esac
