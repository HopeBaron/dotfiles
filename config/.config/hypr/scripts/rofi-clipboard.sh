#!/usr/bin/env bash
# Clipboard history (SUPER+SHIFT+V): cliphist + pins, in rofi. An image entry
# gets a thumbnail, shown small in the list and enlarged in the preview pane
# when highlighted; a text entry has neither -- the pane just stays empty.
#
#   Enter  copy        Alt+p  pin / unpin
#   Alt+d  delete      Alt+w  wipe history (pins are kept)
#
# Pins are copies kept outside cliphist ($PIN_DIR), so they survive a wipe:
# <id>.bin (payload), <id>.mime, <id>.txt (the preview line shown in the menu).
set -euo pipefail
# shellcheck source=../../../../lib/mars.sh
. "$(dirname "$(readlink -f "$0")")/../../../../lib/mars.sh"

readonly PIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cliphist/pins"
readonly IMAGE_CACHE="$MARS_CACHE_DIR/clipboard"
readonly SEP=$'\x1f'   # field separator inside a row (ASCII unit separator)
readonly FOOTER='<b>Enter</b> copy   <b>Alt+p</b> pin/unpin   <b>Alt+d</b> delete   <b>Alt+w</b> wipe'
readonly PIN_ICON=$'\U000f0403'   # nf-md-pin, shown inline before a pinned entry's text

# rofi exit codes: 0 Enter, 1 Esc, 10+N for -kb-custom-(N+1).
readonly KEY_PIN=10 KEY_DELETE=11 KEY_WIPE=12

mkdir -p "$PIN_DIR" "$IMAGE_CACHE"

# ---- the "currently on the clipboard" marker ---------------------------------

# The live clipboard, normalized the way cliphist normalizes its previews
# (whitespace runs -> one space, leading space dropped). Empty for images.
current_clipboard() {
  wl-paste --no-newline 2>/dev/null | tr -s '[:space:]' ' ' | sed 's/^ //' | head -c 200 || true
}

# cliphist cuts previews short and ends them in "…", so a row is current when
# its preview (minus the "…") is a prefix of the clipboard, not when equal.
is_current() {
  local preview=$1
  [[ -n "$CURRENT" && "$CURRENT" == "${preview%…}"* ]]
}

# ---- image previews ------------------------------------------------------------

is_image_preview() { [[ "$1" == "[[ binary data "*" ]]" ]]; }

# Decodes a cliphist image entry once, returns a thumbnail path for rofi.
history_image() {
  local line=$1 id=${1%%$'\t'*}
  local file="$IMAGE_CACHE/$id"
  [[ -s "$file" ]] || printf '%s' "$line" | cliphist decode > "$file" 2>/dev/null || return 1
  thumbnail "$file"
}

pin_image() {
  local id=$1
  [[ "$(cat "$PIN_DIR/$id.mime" 2>/dev/null)" == image/* ]] || return 1
  thumbnail "$PIN_DIR/$id.bin"
}

# Cached decodes for entries no longer in history.
prune_image_cache() {
  local file id
  for file in "$IMAGE_CACHE"/*; do
    [[ -e "$file" ]] || continue
    id=${file##*/}
    [[ -n "${LISTED_IDS[$id]:-}" ]] || rm -f "$file" "$(thumbnail_path "$file")"
  done
}

# ---- building the menu -------------------------------------------------------

# "N  ● 󰐃 text", matching the window switcher's rows: a running number --
# baked into the label itself, not rofi's element-index (see preview.rasi;
# that widget stops at 10 regardless of how long the list actually is) --
# then the ● "on the clipboard now" marker, then a pin glyph if pinned.
label() {
  local number=$1 preview=$2 pinned=$3 mark="  "
  is_current "$preview" && mark="● "
  printf '%d  %s%s%s' "$number" "$mark" "${pinned:+$PIN_ICON }" "$preview"
}

# One row per entry: kind <SEP> key <SEP> label <SEP> icon-path
#   kind  pin | hist      key  pin id | the full `cliphist list` line
#   icon  always set: a real thumbnail for an image, the placeholder for text
collect_rows() {
  local n=0 file id preview line icon
  declare -A pinned_previews=()
  declare -gA LISTED_IDS=()

  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    id=$(basename "$file" .txt)
    preview=$(head -c 200 "$file")
    pinned_previews["$preview"]=1
    n=$((n + 1))
    icon=$(pin_image "$id") || icon=""   # text: no icon -- the pane stays empty for it
    printf 'pin%s%s%s%s%s%s\n' "$SEP" "$id" "$SEP" "$(label "$n" "$preview" 1)" "$SEP" "$icon"
  done < <(ls -t "$PIN_DIR"/*.txt 2>/dev/null || true)

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    preview=${line#*$'\t'}
    [[ -n "${pinned_previews["$preview"]:-}" ]] && continue   # already listed as a pin
    n=$((n + 1))
    icon=""   # text: no icon -- the pane stays empty for it
    if is_image_preview "$preview"; then
      LISTED_IDS[${line%%$'\t'*}]=1
      icon=$(history_image "$line") || icon=""
    fi
    printf 'hist%s%s%s%s%s%s\n' "$SEP" "$line" "$SEP" "$(label "$n" "$preview" "")" "$SEP" "$icon"
  done < <(cliphist list 2>/dev/null || true)

  # Here, not in main: this function runs in a $(...) subshell, so
  # LISTED_IDS only exists inside it.
  prune_image_cache
}

# rofi input: the label, plus its icon (an image entry's thumbnail; empty
# for text) as the row's element-icon, enlarged in the preview pane when
# that row is highlighted.
menu_lines() {
  local kind key label icon
  while IFS="$SEP" read -r kind key label icon; do
    if [[ -n "$icon" ]]; then printf '%s\0icon\x1f%s\n' "$label" "$icon"
    else                      printf '%s\n' "$label"
    fi
  done
}

# ---- actions -----------------------------------------------------------------

payload() {
  local kind=$1 key=$2
  if [[ "$kind" == pin ]]; then cat "$PIN_DIR/$key.bin"
  else printf '%s' "$key" | cliphist decode
  fi
}

copy_entry() {
  local kind=$1 key=$2 mime=text/plain
  [[ "$kind" == pin && -r "$PIN_DIR/$key.mime" ]] && mime=$(cat "$PIN_DIR/$key.mime")
  payload "$kind" "$key" | wl-copy --type "$mime"
}

unpin() {
  local id=$1 preview
  preview=$(cat "$PIN_DIR/$id.txt" 2>/dev/null || true)
  # Put it back into history if it has since dropped out, so unpinning never
  # loses the item.
  if [[ -n "$preview" ]] && ! cliphist list | grep -qF -- "$preview"; then
    cliphist store < "$PIN_DIR/$id.bin"
  fi
  rm -f "$PIN_DIR/$id".{bin,mime,txt}
  notify clipboard "Unpinned" "Kept in history"
}

pin() {
  local line=$1 tmp id
  tmp=$(mktemp)
  payload hist "$line" > "$tmp"
  id=$(sha256sum "$tmp" | cut -c1-12)
  if [[ -e "$PIN_DIR/$id.bin" ]]; then
    rm -f "$tmp"
    notify clipboard "Already pinned"
    return
  fi
  mv "$tmp" "$PIN_DIR/$id.bin"
  file -b --mime-type "$PIN_DIR/$id.bin" > "$PIN_DIR/$id.mime"
  printf '%s' "${line#*$'\t'}" > "$PIN_DIR/$id.txt"
  notify clipboard "Pinned"
}

toggle_pin() {
  if [[ "$1" == pin ]]; then unpin "$2"; else pin "$2"; fi
}

delete_entry() {
  local kind=$1 key=$2 preview
  if [[ "$kind" == pin ]]; then
    preview=$(cat "$PIN_DIR/$key.txt" 2>/dev/null || true)
    rm -f "$PIN_DIR/$key".{bin,mime,txt}
    [[ -n "$preview" ]] && { cliphist list | grep -F -- "$preview" | cliphist delete 2>/dev/null || true; }
  else
    printf '%s' "$key" | cliphist delete
  fi
  notify clipboard "Deleted"
}

wipe_history() {
  local answer
  answer=$(printf 'No, keep it\nYes, wipe history\n' |
    rofi -dmenu -i -mesg "Wipe clipboard history? Pins are kept" \
         -theme-str 'window { width: 360px; } listview { lines: 2; }') || return 0
  if [[ "$answer" == "Yes, wipe history" ]]; then
    cliphist wipe
    local file
    for file in "$IMAGE_CACHE"/*; do rm -f "$file" "$(thumbnail_path "$file")"; done
    notify clipboard "History wiped" "Pins kept"
  fi
}

# ---- main loop: the menu re-opens after pin/delete so you can keep going -----

main() {
  local rows index rc row kind key
  while true; do
    CURRENT=$(current_clipboard)
    rows=$(collect_rows)
    if [[ -z "$rows" ]]; then
      notify clipboard "Clipboard is empty"
      exit 0
    fi

    rc=0
    index=$(printf '%s\n' "$rows" | menu_lines |
      rofi -dmenu -i -format i -theme preview -mesg "$FOOTER" \
           -kb-custom-1 "Alt+p" -kb-custom-2 "Alt+d" -kb-custom-3 "Alt+w") || rc=$?

    if (( rc == KEY_WIPE )); then wipe_history; continue; fi
    [[ -n "$index" ]] || exit 0   # Esc

    row=$(printf '%s\n' "$rows" | sed -n "$((index + 1))p")
    IFS="$SEP" read -r kind key _ _ <<<"$row"

    case "$rc" in
      0)             copy_entry "$kind" "$key"; exit 0 ;;
      "$KEY_PIN")    toggle_pin "$kind" "$key" ;;
      "$KEY_DELETE") delete_entry "$kind" "$key" ;;
      *)             exit 0 ;;
    esac
  done
}

main "$@"
