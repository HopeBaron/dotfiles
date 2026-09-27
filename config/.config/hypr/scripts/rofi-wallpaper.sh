#!/usr/bin/env bash
# Wallpaper picker (SUPER+. -> Wallpaper): every image in the repo's
# wallpapers/ dir, with a large preview of the highlighted one.
#
#   Enter  set for the current theme only
#   Alt+r  set for a chosen set of themes (opens rofi-theme-picker.sh)
set -euo pipefail
SCRIPTS=$(dirname "$(readlink -f "$0")")
# shellcheck source=../../../../lib/mars.sh
. "$SCRIPTS/../../../../lib/mars.sh"

readonly KEY_APPLY_TO=10   # kb-custom-1 = Alt+r

mapfile -t names < <("$MARS_BIN/mars-wallpaper" list)
if (( ${#names[@]} == 0 )); then
  notify wallpaper "No wallpapers yet" "Add images to $MARS_WALLPAPER_DIR"
  exit 0
fi
current=$("$MARS_BIN/mars-wallpaper" current)

# One row per wallpaper: "● name" for the current one, with its thumbnail as
# the row icon (which the preview pane enlarges).
rows() {
  local name mark thumb
  for name in "${names[@]}"; do
    mark="  "
    [[ "$MARS_WALLPAPER_DIR/$name" == "$current" ]] && mark="● "
    thumb=$(thumbnail "$MARS_WALLPAPER_DIR/$name") || thumb=""
    printf '%s%s\0icon\x1f%s\n' "$mark" "$name" "$thumb"
  done
}

current_row=0
for i in "${!names[@]}"; do
  [[ "$MARS_WALLPAPER_DIR/${names[$i]}" == "$current" ]] && current_row=$i
done

# -format i: rofi prints the chosen row's index, so the label never has to
# be parsed back into a file name.
rc=0
index=$(rows | rofi -dmenu -i -format i -theme preview -selected-row "$current_row" \
          -kb-custom-1 "Alt+r" \
          -mesg '<b>Enter</b> set wallpaper   <b>Alt+r</b> apply to several themes') || rc=$?
[[ -n "${index:-}" ]] || exit 0

case "$rc" in
  0)
    "$MARS_BIN/mars-wallpaper" set "${names[$index]}" >/dev/null
    ;;
  "$KEY_APPLY_TO")
    # mapfile itself succeeds regardless of the picker's own exit status
    # (cancel/Escape) -- a cancelled picker just prints nothing, so this
    # emptiness check is what actually catches that case.
    mapfile -t targets < <("$SCRIPTS/rofi-theme-picker.sh")
    (( ${#targets[@]} )) || exit 0
    "$MARS_BIN/mars-wallpaper" set "${names[$index]}" "${targets[@]}" >/dev/null
    ;;
  *) exit 0 ;;
esac
