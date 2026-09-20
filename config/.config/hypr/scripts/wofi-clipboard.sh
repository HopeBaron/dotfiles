#!/usr/bin/env bash
# Clipboard history with pins.
#
#   wofi-clipboard.sh            pick an entry, put it back on the clipboard
#   wofi-clipboard.sh --manage   pin/unpin, delete one entry, or wipe history
#
# History comes from cliphist (recorded by the wl-paste watchers in
# hyprland.lua). Pins are ours: cliphist has no pinning, and `cliphist wipe`
# would take pinned items with it, so pinned payloads are copied out into
# PIN_DIR and survive both a wipe and the 1000-item rollover.
set -euo pipefail

US=$'\x1f'   # field separator; cliphist rows already contain tabs
PIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cliphist/pins"
mkdir -p "$PIN_DIR"

note() { command -v notify-send >/dev/null && notify-send -a clipboard "$1" "${2:-}" || true; }
menu() { wofi --show dmenu --prompt "$1" --width 55% --height 50% --cache-file /dev/null; }

# Emit rows as: KIND US KEY US LABEL
collect_rows() {
  local n=0 f id preview line
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    id=$(basename "$f" .txt)
    preview=$(head -c 200 "$f")
    n=$((n + 1))
    printf 'pin%s%s%s%d  󰐃 %s\n' "$US" "$id" "$US" "$n" "$preview"
  done < <(ls -t "$PIN_DIR"/*.txt 2>/dev/null || true)

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$((n + 1))
    printf 'hist%s%s%s%d  %s\n' "$US" "$line" "$US" "$n" "${line#*	}"
  done < <(cliphist list 2>/dev/null || true)
}

# Show the list, return the full row the user picked.
choose() {
  local rows choice
  rows=$(collect_rows)
  [ -z "$rows" ] && { note "Clipboard is empty"; exit 0; }
  choice=$(printf '%s\n' "$rows" | cut -d"$US" -f3 | menu "$1") || exit 0
  [ -z "$choice" ] && exit 0
  printf '%s\n' "$rows" | awk -F"$US" -v c="$choice" '$3 == c { print; exit }'
}

payload_of() {   # KIND KEY -> raw bytes on stdout
  if [ "$1" = pin ]; then cat "$PIN_DIR/$2.bin"
  else printf '%s' "$2" | cliphist decode
  fi
}

copy_entry() {
  local kind=$1 key=$2 mime=text/plain
  [ "$kind" = pin ] && [ -r "$PIN_DIR/$key.mime" ] && mime=$(cat "$PIN_DIR/$key.mime")
  payload_of "$kind" "$key" | wl-copy --type "$mime"
}

pin_entry() {
  local kind=$1 key=$2 tmp id
  tmp=$(mktemp); trap 'rm -f "$tmp"' RETURN
  payload_of "$kind" "$key" > "$tmp"
  id=$(sha256sum "$tmp" | cut -c1-12)          # hash doubles as dedupe
  [ -e "$PIN_DIR/$id.bin" ] && { note "Already pinned"; return; }
  cp "$tmp" "$PIN_DIR/$id.bin"
  file -b --mime-type "$tmp" > "$PIN_DIR/$id.mime"
  printf '%s' "${key#*	}" > "$PIN_DIR/$id.txt"
  note "Pinned"
}

unpin_entry() { rm -f "$PIN_DIR/$1.bin" "$PIN_DIR/$1.mime" "$PIN_DIR/$1.txt"; note "Unpinned"; }

delete_entry() {
  local kind=$1 key=$2
  if [ "$kind" = pin ]; then unpin_entry "$key"
  else printf '%s' "$key" | cliphist delete; note "Deleted"
  fi
}

wipe_history() {
  # Destructive and unprompted otherwise, so confirm. Pins are untouched.
  local ans
  ans=$(printf 'No, keep it\nYes, wipe history\n' | menu "Wipe all history? Pins are kept") || exit 0
  case "$ans" in
    "Yes, wipe history") cliphist wipe; note "History wiped" "Pins kept" ;;
    *) exit 0 ;;
  esac
}

case "${1:-}" in
  "")
    row=$(choose "Clipboard") || exit 0
    [ -z "$row" ] && exit 0
    copy_entry "$(cut -d"$US" -f1 <<<"$row")" "$(cut -d"$US" -f2 <<<"$row")"
    ;;
  --manage)
    row=$(choose "Clipboard · manage") || exit 0
    [ -z "$row" ] && exit 0
    kind=$(cut -d"$US" -f1 <<<"$row"); key=$(cut -d"$US" -f2 <<<"$row")

    if [ "$kind" = pin ]; then actions=$'Copy\nUnpin\nDelete\nWipe history'
    else actions=$'Copy\nPin\nDelete\nWipe history'; fi

    action=$(printf '%s\n' "$actions" | menu "Action") || exit 0
    case "$action" in
      Copy)           copy_entry "$kind" "$key" ;;
      Pin)            pin_entry  "$kind" "$key" ;;
      Unpin)          unpin_entry "$key" ;;
      Delete)         delete_entry "$kind" "$key" ;;
      "Wipe history") wipe_history ;;
      *) exit 0 ;;
    esac
    ;;
  *) echo "usage: ${0##*/} [--manage]" >&2; exit 2 ;;
esac
