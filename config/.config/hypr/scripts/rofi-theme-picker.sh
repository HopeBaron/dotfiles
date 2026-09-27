#!/usr/bin/env bash
# Checkbox list of themes, for bulk-applying an accent or wallpaper to more
# than one at once (Alt+R in rofi-accent.sh / rofi-wallpaper.sh).
#
#   Alt+Space toggle the highlighted theme
#   Alt+a     select all
#   Alt+x     deselect all
#   Enter     confirm -- prints the selected theme ids, one per line
#   Escape    cancel -- prints nothing, exits 1
#
# The current theme starts pre-selected. Toggle is Alt+Space, not plain
# Space -- plain Space types a literal space into the filter box, needed to
# search a multi-word label like "Gruvbox Material" for real. This script's
# Alt+a is entirely separate from rofi-windows.sh's own Alt+a (all-workspaces
# toggle) -- each script's -kb-custom-N is scoped to its own `rofi` call.
set -euo pipefail
# shellcheck source=../../../../lib/mars.sh
. "$(dirname "$(readlink -f "$0")")/../../../../lib/mars.sh"

# rofi exit codes: 0 Enter, 1 Esc, 10+N for -kb-custom-N.
readonly KEY_TOGGLE=10 KEY_SELECT_ALL=11 KEY_DESELECT_ALL=12

readonly CHECKED=$'\U000f0c52'     # nf-md-checkbox_marked
readonly UNCHECKED=$'\U000f0131'   # nf-md-checkbox_blank_outline
readonly CURRENT_MARK='●'

ids=() labels=()
while IFS=$'\t' read -r id label; do
  ids+=("$id"); labels+=("$label")
done < <("$MARS_BIN/mars-theme" list)
current=$("$MARS_BIN/mars-theme" current | awk -F'\t' '$1 == "theme" { print $2 }')

declare -A checked=()
for id in "${ids[@]}"; do
  [[ "$id" == "$current" ]] && checked["$id"]=1
done

rows() {
  local i mark box
  for i in "${!ids[@]}"; do
    box=$UNCHECKED; [[ -n "${checked["${ids[$i]}"]:-}" ]] && box=$CHECKED
    mark=" "; [[ "${ids[$i]}" == "$current" ]] && mark=$CURRENT_MARK
    printf '%s %s  %s\n' "$box" "$mark" "${labels[$i]}"
  done
}

selected_row=0
for i in "${!ids[@]}"; do [[ "${ids[$i]}" == "$current" ]] && selected_row=$i; done

while true; do
  rc=0
  index=$(rows | rofi -dmenu -i -format i -selected-row "$selected_row" \
            -theme-str 'window { width: 520px; } listview { lines: 12; scrollbar: true; }' \
            -kb-custom-1 "Alt+space" -kb-custom-2 "Alt+a" -kb-custom-3 "Alt+x" \
            -mesg '<b>Alt+Space</b> toggle   <b>Alt+a</b> all   <b>Alt+x</b> none   <b>Enter</b> apply') || rc=$?

  case "$rc" in
    0) break ;;   # Enter: confirm whatever is currently checked
    "$KEY_TOGGLE")
      [[ -n "${index:-}" ]] || continue
      selected_row=$index
      id=${ids[$index]}
      if [[ -n "${checked["$id"]:-}" ]]; then unset 'checked[$id]'; else checked["$id"]=1; fi
      ;;
    "$KEY_SELECT_ALL")
      for id in "${ids[@]}"; do checked["$id"]=1; done
      [[ -n "${index:-}" ]] && selected_row=$index
      ;;
    "$KEY_DESELECT_ALL")
      checked=()
      [[ -n "${index:-}" ]] && selected_row=$index
      ;;
    *) exit 1 ;;   # Escape: cancel, nothing printed
  esac
done

for id in "${ids[@]}"; do
  [[ -n "${checked["$id"]:-}" ]] && printf '%s\n' "$id"
done
