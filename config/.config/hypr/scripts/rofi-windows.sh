#!/usr/bin/env bash
# Window switcher: list open windows and focus the chosen one.
#
#   rofi-windows.sh --workspace   windows on the active workspace (default)
#   rofi-windows.sh --global      every window, tagged with its workspace
#
# rofi has a built-in `window` mode, but it only sees the active workspace on
# Hyprland, so the list is built from `hyprctl clients` instead.
set -euo pipefail

scope=${1:---workspace}
active=$(hyprctl activewindow -j | jq -r '.address // empty')

case "$scope" in
  --workspace|-w)
    ws=$(hyprctl activeworkspace -j | jq -r '.id')
    prompt="Windows · ws $ws"
    sel="select(.workspace.id == \$ws)"
    label='"\(.key + 1)  \(.value.mark)\(.value.class)  ·  \(.value.title)"'
    ;;
  --global|-g)
    ws=-1
    prompt="Windows · all"
    sel="."
    label='"\(.key + 1)  \(.value.mark)[\(.value.workspace.name)] \(.value.class)  ·  \(.value.title)"'
    ;;
  *) echo "usage: ${0##*/} [--workspace|--global]" >&2; exit 2 ;;
esac

# address \t label, most-recently-focused first; the active window is marked.
mapfile -t rows < <(
  hyprctl clients -j | jq -r --argjson ws "$ws" --arg active "$active" "
    map(select(.mapped and (.hidden | not)))
    | map($sel)
    | sort_by(.focusHistoryID)
    | map(. + {
        mark:  (if .address == \$active then \"● \" else \"  \" end),
        title: (.title | if length > 70 then .[0:70] + \"…\" else . end)
      })
    | to_entries[]
    | \"\(.value.address)\t\" + $label
  "
)

[ "${#rows[@]}" -eq 0 ] && exit 0

choice=$(printf '%s\n' "${rows[@]}" | cut -f2- | rofi -dmenu -i -p "$prompt")
[ -z "$choice" ] && exit 0

addr=$(printf '%s\n' "${rows[@]}" | awk -F'\t' -v c="$choice" '$2 == c { print $1; exit }')
[ -n "$addr" ] && hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })"
