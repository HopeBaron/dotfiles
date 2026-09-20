#!/usr/bin/env bash
# Screenshot menu. One interface, like the clipboard picker: the list picks the
# mode, the footer keys pick the destination.
#
#   Enter  -> save to disk AND copy to the clipboard (hyprshot's default)
#   Alt+c  -> copy to the clipboard only, nothing written to disk
#
# The mode used last is pre-selected, so a double-tap of Print repeats it.
set -euo pipefail

state="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
last_file="$state/screenshot-mode"
mkdir -p "$state"

# Respect the user's real Pictures dir when xdg-user-dirs is installed; it is
# not a hard dependency, so fall back rather than requiring the package.
pics=""
command -v xdg-user-dir >/dev/null && pics=$(xdg-user-dir PICTURES 2>/dev/null || true)
[ -n "$pics" ] || pics="$HOME/Pictures"
outdir="$pics/Screenshots"

modes=(region window output)
labels=("  Region" "  Window" "  Full screen")

# Pre-select whatever was used last; default to region on a first run.
last=$(cat "$last_file" 2>/dev/null || true)
selected=0
for i in "${!modes[@]}"; do
  [ "${modes[$i]}" = "$last" ] && selected=$i
done

FOOTER='<b>Enter</b> save + copy   <b>Alt+c</b> copy only'

# rofi exits non-zero for Escape (1) and for each -kb-custom-N (10 + N - 1),
# so the call must not trip `set -e`.
set +e
# rofi single-instances itself through a pidfile lock, so with a menu already
# open a second one dies with "Rofi already running?" and Print looks dead.
# Its own pidfile lets this menu open on top of another rofi -- which is the
# point, since that other menu is usually what you are trying to capture.
pidfile="${XDG_RUNTIME_DIR:-/tmp}/rofi-screenshot.pid"

choice=$(printf '%s\n' "${labels[@]}" | rofi -dmenu -i -p "Screenshot" \
  -pid "$pidfile" \
  -selected-row "$selected" -mesg "$FOOTER" \
  -theme-str 'window { width: 360px; } listview { lines: 3; }')
rc=$?
set -e

[ -n "${choice:-}" ] || exit 0

mode=""
for i in "${!labels[@]}"; do
  [ "${labels[$i]}" = "$choice" ] && mode=${modes[$i]}
done
[ -n "$mode" ] || exit 0

printf '%s\n' "$mode" > "$last_file"

# "output" on its own still opens slurp to pick a monitor, which is a pointless
# click on a single-head machine. hyprshot takes -m twice, and the second
# "active" means "the monitor already focused" -- verified: without it the run
# ends in "selection cancelled / invalid geometry" and writes nothing.
args=(-m "$mode")
[ "$mode" = "output" ] && args+=(-m active)

case "$rc" in
  0)  mkdir -p "$outdir"
      hyprshot "${args[@]}" -o "$outdir" ;;
  13) hyprshot "${args[@]}" --clipboard-only ;;   # kb-custom-4 = Alt+c
  *)  exit 0 ;;
esac
