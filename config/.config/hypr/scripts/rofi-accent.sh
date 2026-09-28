#!/usr/bin/env bash
# Accent picker (SUPER+. -> Accent): the theme's own Gruvbox colours, shown
# as swatches in their real colour, or any custom #rrggbb.
#
#   Enter  apply to the current theme only
#   Alt+r  apply to a chosen set of themes (opens rofi-theme-picker.sh)
#
# A palette name follows the theme it's applied to (e.g. "green" is a darker
# green on light themes); a custom hex stays fixed across theme switches.
# "Reset to default" clears the current theme's own remembered accent, so it
# goes back to carrying forward whatever's active, like an untouched theme.
set -euo pipefail
SCRIPTS=$(dirname "$(readlink -f "$0")")
# shellcheck source=../../../../lib/mars.sh
. "$SCRIPTS/../../../../lib/mars.sh"
# shellcheck source=../../../../theme/lib.sh
. "$MARS_REPO/theme/lib.sh"

readonly KEY_APPLY_TO=10   # kb-custom-1 = Alt+r
readonly CUSTOM_ROW=${#MARS_ACCENT_NAMES[@]}   # "Custom hex..." row
readonly RESET_ROW=$((CUSTOM_ROW + 1))         # "Reset to default" row

theme_activate   # palette of the current theme, for the swatches; sets ACCENT_SPEC

# A round swatch in the colour itself. The current accent is tagged after its
# name rather than with the usual ● marker, which would read as a second
# swatch here.
swatch()  { printf '<span foreground="#%s" size="large">●</span>' "$1"; }
current() { printf '  <span foreground="#%s" size="small">current</span>' "$GREY1"; }
blank()   { printf '<span size="large"> </span>'; }

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
    printf '%s   Custom hex…\n' "$(blank)"
  fi
  printf '%s   ↺ Reset to default\n' "$(blank)"
}

current_row=$CUSTOM_ROW
for i in "${!MARS_ACCENT_NAMES[@]}"; do
  [[ "${MARS_ACCENT_NAMES[$i]}" == "$ACCENT_SPEC" ]] && current_row=$i
done

# The accent spec for row $1 -- prompting for a hex value if "Custom hex..."
# has no value yet. Empty output (with a non-zero return) means cancelled.
spec_for_row() {
  local idx=$1
  case "$idx" in
    "$RESET_ROW") echo reset ;;
    "$CUSTOM_ROW")
      if accent_is_hex "$ACCENT_SPEC"; then
        echo "$ACCENT_SPEC"
      else
        local hex
        hex=$(rofi -dmenu -p '#' </dev/null \
                -theme-str 'listview { enabled: false; } entry { placeholder: "rrggbb, e.g. d65d0e"; }' \
                -mesg 'Type a hex colour and press <b>Enter</b>') || return 1
        accent_is_hex "$hex" || { notify theme "Not a colour: $hex" "Use six hex digits, like d65d0e"; return 1; }
        echo "#${hex#\#}"
      fi
      ;;
    *) echo "${MARS_ACCENT_NAMES[$idx]}" ;;
  esac
}

rc=0
index=$(rows | rofi -dmenu -i -markup-rows -format i -selected-row "$current_row" \
          -kb-custom-1 "Alt+r" \
          -theme-str 'window { width: 320px; } listview { lines: 9; }' \
          -mesg '<b>Enter</b> apply   <b>Alt+r</b> apply to several themes') || rc=$?
[[ -n "${index:-}" ]] || exit 0

case "$rc" in
  0)
    spec=$(spec_for_row "$index") || exit 0
    "$MARS_BIN/mars-theme" accent "$spec"
    ;;
  "$KEY_APPLY_TO")
    spec=$(spec_for_row "$index") || exit 0
    targets=()
    pick_themes targets
    "$MARS_BIN/mars-theme" accent "$spec" "${targets[@]}"
    ;;
  *) exit 0 ;;
esac
