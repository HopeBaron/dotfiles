#!/usr/bin/env bash
# Keep-awake toggle ("caffeine"). SUPER+SHIFT+` and the waybar coffee-cup
# module both call this. Backed by `systemd-inhibit --what=idle`, which
# hypridle honours automatically -- hypridle.conf never sets
# ignore_dbus_inhibit/ignore_systemd_inhibit, so its default (false, i.e.
# "do respect inhibitors") applies, and an active inhibit pauses every
# hypridle listener (dim/lock/suspend) until it's released.
set -euo pipefail

readonly PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/caffeine.pid"

is_active() {
  [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null
}

# waybar's own status line for the module (format/tooltip/class -- class
# drives the on/off colouring in waybar-style.css).
status() {
  if is_active; then
    printf '{"text":"","tooltip":"Caffeine: on -- screen won'"'"'t sleep","class":"active"}\n'
  else
    printf '{"text":"","tooltip":"Caffeine: off","class":"inactive"}\n'
  fi
}

toggle() {
  if is_active; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
    notify-send -a caffeine "Caffeine off" "Idle timeouts restored" 2>/dev/null || true
  else
    setsid systemd-inhibit --what=idle --who="Caffeine" \
      --why="Manually kept awake" sleep infinity &
    echo $! > "$PID_FILE"
    notify-send -a caffeine "Caffeine on" "Screen will stay awake" 2>/dev/null || true
  fi
  # Nudges waybar's custom/caffeine module to re-run its exec immediately
  # instead of waiting for its next interval.
  pkill -RTMIN+8 waybar 2>/dev/null || true
}

case "${1:-status}" in
  toggle) toggle ;;
  status) status ;;
  *) echo "usage: $0 [status|toggle]" >&2; exit 1 ;;
esac
