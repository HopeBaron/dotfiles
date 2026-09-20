#!/usr/bin/env bash
# Clipboard history with pins, in one menu.
#
#   Enter   copy the entry back to the clipboard
#   Alt+p   pin / unpin
#   Alt+d   delete this entry
#   Alt+w   wipe history (pins are kept)
#
# History comes from cliphist (recorded by the wl-paste watchers in
# hyprland.lua). Pins are ours: cliphist has no pinning and its wipe takes
# everything, so pinned payloads are copied out into PIN_DIR, where they
# survive both a wipe and the item rollover.
set -euo pipefail

US=$'\x1f'   # field separator; cliphist rows already contain tabs
PIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cliphist/pins"
mkdir -p "$PIN_DIR"

FOOTER='<b>Enter</b> copy   <b>Alt+p</b> pin/unpin   <b>Alt+d</b> delete   <b>Alt+w</b> wipe'

note() { command -v notify-send >/dev/null && notify-send -a clipboard "$1" "${2:-}" || true; }

# Emit rows as: KIND US KEY US LABEL
collect_rows() {
  local n=0 f id preview line
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    id=$(basename "$f" .txt); preview=$(head -c 200 "$f")
    n=$((n + 1)); printf 'pin%s%s%s%d  󰐃 %s\n' "$US" "$id" "$US" "$n" "$preview"
  done < <(ls -t "$PIN_DIR"/*.txt 2>/dev/null || true)

  while IFS= read -r line; do
    [ -n "$line" ] || continue
    n=$((n + 1)); printf 'hist%s%s%s%d  %s\n' "$US" "$line" "$US" "$n" "${line#*	}"
  done < <(cliphist list 2>/dev/null || true)
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

toggle_pin() {
  local kind=$1 key=$2 tmp id
  if [ "$kind" = pin ]; then
    rm -f "$PIN_DIR/$key.bin" "$PIN_DIR/$key.mime" "$PIN_DIR/$key.txt"; note "Unpinned"; return
  fi
  tmp=$(mktemp); trap 'rm -f "$tmp"' RETURN
  payload_of "$kind" "$key" > "$tmp"
  id=$(sha256sum "$tmp" | cut -c1-12)          # hash doubles as dedupe
  [ -e "$PIN_DIR/$id.bin" ] && { note "Already pinned"; return; }
  cp "$tmp" "$PIN_DIR/$id.bin"
  file -b --mime-type "$tmp" > "$PIN_DIR/$id.mime"
  printf '%s' "${key#*	}" > "$PIN_DIR/$id.txt"
  note "Pinned"
}

delete_entry() {
  local kind=$1 key=$2
  if [ "$kind" = pin ]; then
    rm -f "$PIN_DIR/$key.bin" "$PIN_DIR/$key.mime" "$PIN_DIR/$key.txt"; note "Unpinned"
  else
    printf '%s' "$key" | cliphist delete; note "Deleted"
  fi
}

wipe_history() {
  # Destructive, so confirm. Pins live outside the db and are untouched.
  local ans
  ans=$(printf 'No, keep it\nYes, wipe history\n' \
        | rofi -dmenu -i -p "Wipe history?" -mesg "Pins are kept" \
               -theme-str 'window { width: 360px; } listview { lines: 2; }') || return 0
  [ "$ans" = "Yes, wipe history" ] && { cliphist wipe; note "History wiped" "Pins kept"; }
}

while true; do
  rows=$(collect_rows)
  [ -z "$rows" ] && { note "Clipboard is empty"; exit 0; }

  set +e
  choice=$(printf '%s\n' "$rows" | cut -d"$US" -f3 \
           | rofi -dmenu -i -p "Clipboard" -mesg "$FOOTER")
  rc=$?
  set -e
  [ -z "${choice:-}" ] && exit 0

  row=$(printf '%s\n' "$rows" | awk -F"$US" -v c="$choice" '$3 == c { print; exit }')
  [ -z "$row" ] && exit 0
  kind=$(cut -d"$US" -f1 <<<"$row"); key=$(cut -d"$US" -f2 <<<"$row")

  # rofi exits 0 on Enter, 1 on Escape, and 10+N-1 for -kb-custom-N.
  case "$rc" in
    0)  copy_entry "$kind" "$key"; exit 0 ;;
    10) toggle_pin "$kind" "$key" ;;      # Alt+p -- reopen so you can pin more
    11) delete_entry "$kind" "$key" ;;    # Alt+d
    12) wipe_history ;;                   # Alt+w
    *)  exit 0 ;;
  esac
done
