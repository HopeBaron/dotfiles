#!/usr/bin/env bash
# Theme picker (SUPER+. -> Theme): GruvMoon and every Gruvbox Material
# variant (dark/light x hard/medium/soft x material/mix/original).
set -euo pipefail
# shellcheck source=../../../../lib/mars.sh
. "$(dirname "$(readlink -f "$0")")/../../../../lib/mars.sh"

readonly ICON_DARK=$'\U000f0594'   # nf-md-weather_night
readonly ICON_LIGHT=$'\U000f05a8'  # nf-md-white_balance_sunny

ids=() labels=()
mars_theme_list ids labels
current=$(mars_theme_current)

rows() {
  local i mark icon
  for i in "${!ids[@]}"; do
    mark="  "; [[ "${ids[$i]}" == "$current" ]] && mark="● "
    icon=$ICON_DARK; [[ "${ids[$i]}" == *-light-* ]] && icon=$ICON_LIGHT
    printf '%s%s  %s\n' "$mark" "$icon" "${labels[$i]}"
  done
}

current_row=0
for i in "${!ids[@]}"; do [[ "${ids[$i]}" == "$current" ]] && current_row=$i; done

index=$(rows | rofi -dmenu -i -format i -selected-row "$current_row" \
          -theme-str 'window { width: 480px; } listview { lines: 12; scrollbar: true; }' \
          -mesg '<b>Enter</b> apply theme   (accent is kept)') || exit 0
[[ -n "$index" ]] || exit 0

"$MARS_BIN/mars-theme" set "${ids[$index]}"
