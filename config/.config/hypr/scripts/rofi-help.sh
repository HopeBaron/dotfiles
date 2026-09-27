#!/usr/bin/env bash
# Shortcut cheat sheet. SUPER+? opens it.
#
# The Hyprland half is GENERATED from the live binds: every hl.bind carrying a
# `description` shows up here automatically, so adding a bind updates this list
# without touching this file. Binds with no description are deliberately
# skipped -- that is how the twenty numbered workspace binds stay out of the
# way; they get one summary line in EXTRAS instead.
#
# EXTRAS covers what hyprctl cannot know about: the xkb layout toggle, and the
# action keys that only exist inside the other rofi menus.
set -euo pipefail

# Hyprland modmask bits: SHIFT=1 CAPS=2 CTRL=4 ALT=8 SUPER=64.
binds=$(hyprctl binds -j | jq -r '
  def has($m; $bit): (($m / $bit) | floor) % 2 == 1;
  def mods($m):
    [ if has($m;64) then "SUPER" else empty end,
      if has($m;4)  then "CTRL"  else empty end,
      if has($m;8)  then "ALT"   else empty end,
      if has($m;1)  then "SHIFT" else empty end ] | join(" + ");
  .[]
  | select((.description // "") != "")
  | ((mods(.modmask) | if . == "" then "" else . + " + " end) + .key)
    + "\t" + .description
')

EXTRAS=$(cat <<'XEOF'
SUPER + 1 … 0	Go to workspace
SUPER + SHIFT + 1 … 0	Move window to workspace
SUPER + scroll	Previous / next workspace
SUPER + LMB drag	Move window
SUPER + RMB drag	Resize window
SUPER + Space	Cycle keyboard layout (en / ar)
	
Alt + p	Clipboard menu: pin / unpin
Alt + d	Clipboard menu: delete entry
Alt + w	Clipboard menu: wipe history
Alt + c	Screenshot menu: copy without saving
XEOF
)

printf '%s\n%s\n' "$binds" "$EXTRAS" \
  | awk -F'\t' '{ printf "%-26s %s\n", $1, $2 }' \
  | rofi -dmenu -i -p "Shortcuts" \
      -mesg '<b>Type to filter</b>   <b>Esc</b> close' \
      -theme-str '* { font: "JetBrainsMono Nerd Font 10"; }
                  window { width: 640px; }
                  listview { lines: 16; scrollbar: true; }' \
  > /dev/null || true   # reference only: nothing is actionable
