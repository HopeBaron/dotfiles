#!/usr/bin/env bash
# Power menu, rendered through wofi so it matches the launcher.
set -euo pipefail

# Only offer Lock once a lockscreen is actually installed.
entries=()
command -v hyprlock >/dev/null && entries+=("󰌾  Lock")
entries+=("󰤄  Suspend" "󰗽  Log out" "󰜉  Reboot" "󰐥  Shut down")

choice=$(printf '%s\n' "${entries[@]}" \
  | wofi --show dmenu --prompt "Power" --width 260px --height 260px \
         --cache-file /dev/null --hide-scroll)

case "${choice:-}" in
  *Lock)      hyprlock ;;
  *Suspend)   systemctl suspend ;;
  *"Log out") hyprctl dispatch exit ;;
  *Reboot)    systemctl reboot ;;
  *"Shut down") systemctl poweroff ;;
  *) exit 0 ;;
esac
