#!/usr/bin/env bash
# Window switcher: list open windows and focus the chosen one.
#
# One menu instead of two binds: starts on every window (tagged with its
# workspace), Alt+a toggles to just the active workspace's and back, so switching
# scope never means pressing a different key combo, just a footer action --
# same shape as the clipboard and screenshot menus. Alt+x / Alt+Shift+x close
# or force-close the highlighted window (same two dispatchers as the SUPER+X
# / SUPER+SHIFT+X binds) without leaving the menu, in either scope.
#
# rofi has a built-in `window` mode, but it only sees the active workspace on
# Hyprland, so the list is built from `hyprctl clients` instead.
set -euo pipefail

# rofi exit codes for this script's own -kb-custom-N (10 + N - 1).
readonly KEY_CLOSE=10 KEY_KILL=11 KEY_SCOPE=14

scope=${1:-global}   # global | workspace -- starting scope; Alt+a toggles it

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
    *) echo "usage: ${0##*/} [global|workspace]" >&2; exit 2 ;;
  esac

  # address \t label \t icon, most-recently-focused first; the active window
  # is marked. The icon is just the window's own class/app-id, unresolved --
  # rofi looks it up in the icon theme itself (config.rasi's show-icons), and
  # a class like "firefox" or "org.kde.dolphin" already IS that app's icon
  # name for any icon theme following freedesktop naming, so no lookup table
  # is needed. A class that doesn't resolve just shows no icon for that row.
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
      | \"\(.value.address)\t\" + $label + \"\t\(.value.class)\"
    "
  )

  # Show the menu even with nothing to list -- an empty workspace should
  # still open, with an inert placeholder row, so Alt+a stays reachable
  # instead of the whole thing silently doing nothing. Piped straight into
  # rofi rather than built up in a `list=$(...)` variable first: the icon
  # field below embeds a NUL byte, which command substitution silently
  # drops, breaking every row's icon at once.
  print_rows() {
    if [ "${#rows[@]}" -eq 0 ]; then
      printf '%s\n' "(no windows)"
    else
      printf '%s\n' "${rows[@]}" | awk -F'\t' '{ printf "%s\0icon\x1f%s\n", $2, $3 }'
    fi
  }

  # rofi exits non-zero for Escape (1) and for each -kb-custom-N (10+N-1);
  # `|| rc=$?` records that instead of letting `set -e` end the script.
  rc=0
  choice=$(print_rows \
    | rofi -dmenu -i -p "$prompt" \
           -mesg "<b>Enter</b> focus   <b>Alt+x</b> close   <b>Alt+Shift+x</b> force close   <b>Alt+a</b> $hint" \
           -kb-custom-1 "Alt+x" -kb-custom-2 "Alt+shift+x" -kb-custom-5 "Alt+a") || rc=$?

  if [ "$rc" -eq "$KEY_SCOPE" ]; then
    [ "$scope" = workspace ] && scope=global || scope=workspace
    continue
  fi

  [ -z "${choice:-}" ] && exit 0
  [ "${#rows[@]}" -eq 0 ] && exit 0   # only the placeholder row existed
  addr=$(printf '%s\n' "${rows[@]}" | awk -F'\t' -v c="$choice" '$2 == c { print $1; exit }')
  [ -n "$addr" ] || exit 0

  case "$rc" in
    "$KEY_CLOSE") hyprctl dispatch "hl.dsp.window.close({ window = \"address:$addr\" })"; continue ;;
    "$KEY_KILL")  hyprctl dispatch "hl.dsp.window.kill({ window = \"address:$addr\" })";  continue ;;
    *) hyprctl dispatch "hl.dsp.focus({ window = \"address:$addr\" })" ;;
  esac
  exit 0
done
