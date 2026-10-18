#!/usr/bin/env bash
# Clickable workspace buttons for waybar, standing in for the built-in
# hyprland/workspaces module. That module switches workspace by sending the
# classic `dispatch workspace N` over IPC, which this Hyprland's Lua config
# rejects (it parses every dispatch as Lua), so its buttons can't be clicked.
# Here each workspace is its own custom/wsN module whose on-click sends the
# Lua form instead.
#
#   workspaces.sh show N    -- waybar status line for workspace N
#   workspaces.sh focus N   -- switch to workspace N (on-click)
#   workspaces.sh listen    -- refresh every button on workspace events
set -euo pipefail

# Must match "signal" on the custom/wsN modules in waybar-config.jsonc.
readonly SIGNAL=9

# Hidden (empty text) unless the workspace exists or is the active one --
# the same set the built-in module showed.
show() {
  local n=$1
  if [[ $(hyprctl activeworkspace -j | jq .id) == "$n" ]]; then
    printf '{"text":"%s","class":["ws","active"]}\n' "$n"
  elif hyprctl workspaces -j | jq -e --argjson n "$n" 'any(.[]; .id == $n)' >/dev/null; then
    printf '{"text":"%s","class":["ws"]}\n' "$n"
  else
    printf '{"text":""}\n'
  fi
}

focus() {
  hyprctl dispatch "hl.dsp.focus({ workspace = $1 })" >/dev/null
}

# Runs as its own (always empty, so never drawn) waybar module, so it lives
# and dies with the bar.
listen() {
  local sock="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
  socat -u "UNIX-CONNECT:$sock" - | while IFS= read -r line; do
    case $line in
      workspace\>\>*|createworkspace\>\>*|destroyworkspace\>\>*|focusedmon\>\>*|moveworkspace\>\>*)
        pkill -RTMIN+"$SIGNAL" -x waybar || true ;;
    esac
  done
}

case ${1:-} in
  show)   show "$2" ;;
  focus)  focus "$2" ;;
  listen) listen ;;
  *) echo "usage: ${0##*/} show N | focus N | listen" >&2; exit 2 ;;
esac
