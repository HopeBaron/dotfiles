#!/usr/bin/env bash
# Utilities menu (SUPER+.): one entry point for the look-and-feel pickers.
set -euo pipefail

scripts=$(dirname "$(readlink -f "$0")")

# label                         script
entries=(
  $'\U000f0e09  Wallpaper'     "$scripts/rofi-wallpaper.sh"
  $'\U000f03d8  Theme'         "$scripts/rofi-theme.sh"
  $'\U000f0765  Accent colour' "$scripts/rofi-accent.sh"
)

labels=()
for (( i = 0; i < ${#entries[@]}; i += 2 )); do labels+=("${entries[i]}"); done

index=$(printf '%s\n' "${labels[@]}" | rofi -dmenu -i -format i \
          -theme-str 'window { width: 300px; } listview { lines: 3; }') || exit 0
[[ -n "$index" ]] || exit 0

exec "${entries[index * 2 + 1]}"
