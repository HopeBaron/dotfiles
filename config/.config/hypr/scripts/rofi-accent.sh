#!/usr/bin/env bash
# Accent picker (SUPER+. -> Accent): the theme's own Gruvbox colours, shown
# as swatches in their real colour, or any custom #rrggbb.
#
# A palette name follows the theme (e.g. "green" is a darker green on light
# themes); a custom hex stays fixed across theme switches.
set -euo pipefail
# shellcheck source=../../../../lib/mars.sh
. "$(dirname "$(readlink -f "$0")")/../../../../lib/mars.sh"
# shellcheck source=../../../../theme/lib.sh
. "$MARS_REPO/theme/lib.sh"

readonly CUSTOM_ROW=${#MARS_ACCENT_NAMES[@]}   # index of the "Custom" row, after the names

theme_activate   # palette of the current theme, for the swatches; sets ACCENT_SPEC

# A round swatch in the colour itself. The current accent is tagged after its
# name rather than with the usual ● marker, which would read as a second
# swatch here.
swatch()  { printf '<span foreground="#%s" size="large">\u25cf</span>' "$1"; }
current() { printf '  <span foreground="#%s" size="small">current</span>' "$GREY1"; }

rows() {
  local name var tag
  for name in "${MARS_ACCENT_NAMES[@]}"; do
    var=${name^^}
    tag=""; [[ "$ACCENT_SPEC" == "$name" ]] && tag=$(current)
    printf '%s  %s%s\n' "$(swatch "${!var}")" "${name^}" "$tag"
  done
  if accent_is_hex "$ACCENT_SPEC"; then
    printf '%s  Custom %s%s\n' "$(swatch "${ACCENT_SPEC#\#}")" "$ACCENT_SPEC" "$(current)"
  else
    printf '<span size="large"> </span>   Custom hex…\n'
  fi
}

current_row=$CUSTOM_ROW
for i in "${!MARS_ACCENT_NAMES[@]}"; do
  [[ "${MARS_ACCENT_NAMES[$i]}" == "$ACCENT_SPEC" ]] && current_row=$i
done

index=$(rows | rofi -dmenu -i -markup-rows -format i -selected-row "$current_row" \
          -theme-str 'window { width: 320px; } listview { lines: 8; }' \
          -mesg '<b>Enter</b> apply accent') || exit 0
[[ -n "$index" ]] || exit 0

if (( index < CUSTOM_ROW )); then
  "$MARS_BIN/mars-theme" accent "${MARS_ACCENT_NAMES[$index]}"
  exit 0
fi

# Custom: a free-text prompt with no list under it.
hex=$(rofi -dmenu -p '#' -theme-str 'listview { enabled: false; } entry { placeholder: "rrggbb, e.g. d65d0e"; }' \
        -mesg 'Type a hex colour and press <b>Enter</b>' </dev/null) || exit 0
if accent_is_hex "$hex"; then
  "$MARS_BIN/mars-theme" accent "#${hex#\#}"
else
  notify theme "Not a colour: $hex" "Use six hex digits, like d65d0e"
fi
