#!/usr/bin/env bash
# Window switcher: list open windows and focus the chosen one.
#
# One menu instead of two binds: starts on the active workspace, Alt+a
# toggles to every window (tagged with its workspace) and back, so switching
# scope never means pressing a different key combo, just a footer action --
# same shape as the clipboard and screenshot menus.
#
# rofi has a built-in `window` mode, but it only sees the active workspace on
# Hyprland, so the list is built from `hyprctl clients` instead.
set -euo pipefail

scope=${1:-workspace}   # workspace | global -- starting scope; Alt+a toggles it

while :; do
  active=$(hyprctl activewindow -j | jq -r '.address // empty')

  case "$scope" in
    workspace)
      ws=$(hyprctl activeworkspace -j | jq -r '.id')
      prompt="Windows · ws $ws"
      sel="select(.workspace.id == \$ws)"
      label='"\(.key + 1)  \(.value.mark)\(.value.class)  ·  \(.value.title)"'
      hint="all workspaces"
      ;;
    global)
      ws=-1
      prompt="Windows · all"
      sel="."
      label='"\(.key + 1)  \(.value.mark)[\(.value.workspace.name)] \(.value.class)  ·  \(.value.title)"'
      hint="this workspace"
      ;;
    *) echo "usage: ${0##*/} [workspace|global]" >&2; exit 2 ;;
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

  # rofi exits non-zero for Escape (1) and for -kb-custom-5 (14 = 10+5-1), so
  # the call must not trip `set -e`.
  set +e
  choice=$(printf '%s\n' "${rows[@]}" | cut -f2- \
    | rofi -dmenu -i -p "$prompt" -mesg "<b>Enter</b> focus   <b>Alt+a</b> $hint")
  rc=$?
  set -e

  if [ "$rc" -eq 14 ]; then
    [ "$scope" = workspace ] && scope=global || scope=workspace
    continue
  fi

  [ -z "${choice:-}" ] && exit 0
  addr=$(printf '%s\n' "${rows[@]}" | awk -F'\t' -v c="$choice" '$2 == c { print $1; exit }')
  [ -n "$addr" ] && hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })"
  exit 0
done
