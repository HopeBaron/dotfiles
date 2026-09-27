#!/usr/bin/env bash
# Wallpaper picker (SUPER+. -> Wallpaper): every image in the repo's
# wallpapers/ dir, with a large preview of the highlighted one.
set -euo pipefail
# shellcheck source=../../../../lib/mars.sh
. "$(dirname "$(readlink -f "$0")")/../../../../lib/mars.sh"

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
index=$(rows | rofi -dmenu -i -format i -theme preview -selected-row "$current_row" \
          -mesg '<b>Enter</b> set wallpaper') || exit 0
[[ -n "$index" ]] || exit 0

"$MARS_BIN/mars-wallpaper" set "${names[$index]}" >/dev/null
