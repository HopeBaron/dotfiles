#!/usr/bin/env bash
# Screenshot menu (Print). One interface, like the clipboard picker: the list
# picks the mode, the footer keys pick the destination.
#
#   Enter  -> copy to the clipboard only, nothing written to disk
#   Alt+c  -> save to disk AND copy to the clipboard (hyprshot's default)
#
# The mode used last is pre-selected, so a double-tap of Print repeats it.
#
# The last entry opens the recording menu (rofi-recording.sh), where a
# running recording is stopped; while one runs that entry is pre-selected,
# so Print, Enter, Enter stops it.
set -euo pipefail

# ---- freeze, first of all ---------------------------------------------------

# Freeze the screen before rofi opens. rofi takes keyboard focus, and apps
# close their open dropdowns and context menus the moment they lose it -- or
# even on the Print key's own release -- so the menu you pressed Print to
# capture can be gone within milliseconds. hyprpicker shows the frozen frame
# as an overlay; everything after this (rofi, slurp's drag, hyprshot's grim)
# runs on top of that frame.
#
# It starts before anything else in this script, so keep this block cheap:
# no sourcing, no subprocesses -- any delay here lets dropdowns close before
# the freeze. It runs during a recording too (a screenshot mid-recording
# wants the same frame); the video then shows that frame until a choice is
# made, and choosing "Recording…" unfreezes before its menu opens.
freeze_pid=""
if command -v hyprpicker >/dev/null; then
  hyprpicker -r -z >/dev/null 2>&1 &
  freeze_pid=$!
fi

# Whether a recording is running, for the last entry's label. Same check as
# rofi-recording.sh's recording_pid, inlined to stay off the critical path.
recording=0
if { read -r rec_pid < "${XDG_RUNTIME_DIR:-/tmp}/screen-recorder.pid" \
     && read -r rec_comm < "/proc/$rec_pid/comm"; } 2>/dev/null \
   && [[ "$rec_comm" == gpu-screen-reco* ]]; then
  recording=1
fi

unfreeze() {
  [[ -n "$freeze_pid" ]] || return 0
  kill "$freeze_pid" 2>/dev/null || true
  wait "$freeze_pid" 2>/dev/null || true
  freeze_pid=""
}
trap unfreeze EXIT

# rofi has to map after the freeze overlay, or it lands underneath it.
wait_for_freeze() {
  [[ -n "$freeze_pid" ]] || return 0
  for _ in {1..40}; do
    hyprctl layers | grep -q 'namespace: hyprpicker' && return 0
    sleep 0.025
  done
}

# ---- setup ------------------------------------------------------------------

# shellcheck source=../../../../lib/mars.sh
. "$(dirname "$(readlink -f "$0")")/../../../../lib/mars.sh"

readonly LAST_MODE_FILE="$MARS_STATE_DIR/screenshot-mode"
readonly RECORDER="$(dirname "$(readlink -f "$0")")/rofi-recording.sh"

# rofi single-instances itself through a pidfile lock, so with a menu already
# open a second one dies with "Rofi already running?" and Print looks dead.
# Its own pidfile lets this menu open on top of another rofi -- which is the
# point, since that other menu is usually what you are trying to capture.
readonly ROFI_PID="${XDG_RUNTIME_DIR:-/tmp}/rofi-screenshot.pid"

# rofi exit codes: 0 Enter, 1 Esc, 10+N for -kb-custom-(N+1).
readonly KEY_SAVE=13   # -kb-custom-4 = Alt+c

# ---- screenshots ------------------------------------------------------------

screenshot() {
  local mode=$1 rc=$2 outdir
  printf '%s\n' "$mode" > "$LAST_MODE_FILE"

  # "output"/"window" on their own open an interactive picker (slurp for the
  # monitor, a click for the window) instead of using whatever's already
  # focused. That picker click is itself a focus change -- rofi (a layer-shell
  # surface, see rules.lua's "no-anim-rofi") held keyboard focus until it just
  # closed, so clicking a window to select it is a second, visible focus
  # change on top of that. hyprshot takes -m twice; the second "active" skips
  # the picker entirely and targets whatever's already focused -- the window
  # this menu was opened on top of, not whatever a stray click lands on.
  # region has no such picker-free mode; a drag is the whole point there.
  local args=(-m "$mode")
  [[ "$mode" == region ]] || args+=(-m active)

  if (( rc == KEY_SAVE )); then
    outdir="$(user_dir PICTURES "$HOME/Pictures")/Screenshots"
    mkdir -p "$outdir"
    hyprshot "${args[@]}" -o "$outdir"
  else
    hyprshot "${args[@]}" --clipboard-only
  fi
}

# ---- menu -------------------------------------------------------------------

modes=(region window output)
labels=("󰩬  Region" "󰖯  Window" "󰹑  Full screen")

# Pre-select whatever was used last; default to region on a first run.
last=$(cat "$LAST_MODE_FILE" 2>/dev/null || true)
selected=0
for i in "${!modes[@]}"; do
  [[ "${modes[$i]}" == "$last" ]] && selected=$i
done

if (( recording )); then
  labels+=("󰑊  Recording…")
  selected=${#modes[@]}
else
  labels+=("󰑊  Record…")
fi

FOOTER='<b>Enter</b> copy only   <b>Alt+c</b> save + copy'

wait_for_freeze

while true; do
  rc=0
  i=$(printf '%s\n' "${labels[@]}" | rofi -dmenu -i -p "Screenshot" -format i \
    -pid "$ROFI_PID" \
    -selected-row "$selected" -mesg "$FOOTER" \
    -kb-custom-4 "Alt+c" \
    -theme-str "window { width: 360px; } listview { lines: ${#labels[@]}; }") || rc=$?
  [[ -n "${i:-}" ]] || exit 0

  if (( i < ${#modes[@]} )); then
    screenshot "${modes[i]}" "$rc"
    exit 0
  fi

  # Recording needs the live screen, not the frozen frame -- both to start
  # one and to keep a running one from showing a still frame; the recording
  # menu exits 1 on Escape, which comes back here.
  unfreeze
  rec_rc=0
  "$RECORDER" || rec_rc=$?
  (( rec_rc == 1 )) || exit 0
  selected=$i
done
