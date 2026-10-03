#!/usr/bin/env bash
# Clipboard history (SUPER+SHIFT+V): cliphist + pins, in rofi. An image entry
# gets a thumbnail, shown small in the list and enlarged in the preview pane
# when highlighted; a text entry has neither -- the pane just stays empty.
#
#   Enter  copy        Alt+p  pin / unpin
#   Alt+d  delete      Alt+w  wipe history (pins are kept)
#   Alt+q  toggle incognito -- while on, nothing is added to cliphist
#          history; the menu just shows a note instead of the (now stale)
#          list until it's turned back off
#
# Pins are copies kept outside cliphist ($PIN_DIR), so they survive a wipe:
# <id>.bin (payload), <id>.mime, <id>.txt (the preview line shown in the menu).
set -euo pipefail
# shellcheck source=../../../../lib/mars.sh
. "$(dirname "$(readlink -f "$0")")/../../../../lib/mars.sh"

readonly PIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/cliphist/pins"
readonly IMAGE_CACHE="$MARS_CACHE_DIR/clipboard"
readonly SEP=$'\x1f'   # field separator inside a row (ASCII unit separator)
readonly FOOTER_BASE='<b>Enter</b> copy   <b>Alt+p</b> pin/unpin   <b>Alt+d</b> delete   <b>Alt+w</b> wipe'
readonly PIN_ICON=$'\U000f0403'   # nf-md-pin, shown inline before a pinned entry's text

# rofi exit codes: 0 Enter, 1 Esc, 10+N for -kb-custom-(N+1).
readonly KEY_PIN=10 KEY_DELETE=11 KEY_WIPE=12 KEY_INCOGNITO=13

mkdir -p "$PIN_DIR" "$IMAGE_CACHE" "$MARS_STATE_DIR"

# ---- incognito mode -----------------------------------------------------------

# Off by default; persists across runs as a flag file (not a mars.sh concern,
# so it's not there -- just this one script's own toggle).
readonly INCOGNITO_FLAG="$MARS_STATE_DIR/clipboard-incognito"

incognito_on() { [[ -e "$INCOGNITO_FLAG" ]]; }

# autostart.lua runs these two, system-wide, for the life of the session, and
# every clipboard change lands in cliphist history while they're up. Turning
# incognito on kills them outright rather than pausing per-copy: nothing gets
# recorded for as long as incognito stays on, no matter where the copy comes
# from, and history is left stale (the menu just shows a note -- see main())
# rather than paying to keep it current for a list nobody wants right now.
# Turning it back off relaunches them and normal recording resumes.
readonly -a WATCHER_TEXT_CMD=(wl-paste --type text --watch cliphist store)
readonly -a WATCHER_IMAGE_CMD=(wl-paste --type image --watch cliphist store)

toggle_incognito() {
  if incognito_on; then
    rm -f "$INCOGNITO_FLAG"
    pgrep -f "wl-paste --type text --watch cliphist store" >/dev/null 2>&1 \
      || setsid -f "${WATCHER_TEXT_CMD[@]}" >/dev/null 2>&1
    pgrep -f "wl-paste --type image --watch cliphist store" >/dev/null 2>&1 \
      || setsid -f "${WATCHER_IMAGE_CMD[@]}" >/dev/null 2>&1
    notify clipboard "Incognito off" "History is recorded again"
  else
    : > "$INCOGNITO_FLAG"
    pkill -f "wl-paste --type text --watch cliphist store" 2>/dev/null || true
    pkill -f "wl-paste --type image --watch cliphist store" 2>/dev/null || true
    notify clipboard "Incognito on" "Nothing is being recorded"
  fi
}

# A single-row notice, shown instead of the (frozen) history list while
# incognito is on. Enter or Alt+q turns it back off; Esc just leaves.
incognito_notice() {
  local rc=0
  rofi -dmenu -i -format i -mesg "Incognito is on -- history isn't being recorded" \
       -kb-custom-4 "Alt+q" <<<"Turn off incognito" >/dev/null || rc=$?
  case "$rc" in
    0|"$KEY_INCOGNITO") toggle_incognito ;;
    *)                  exit 0 ;;
  esac
}

footer() {
  printf '%s   <b>Alt+q</b> incognito (off)' "$FOOTER_BASE"
}

# A temp file for pin()/copy_entry() to write into before an atomic rename.
# Staged inside $PIN_DIR itself, not /tmp: `mv` is only atomic within one
# filesystem, and /tmp is commonly a separate tmpfs, so renaming in from
# there can silently degrade to a copy+delete -- a kill mid-write could then
# leave a half-written file sitting at the final name. The leading dot keeps
# it out of collect_rows()'s `*.txt` glob, so a stray one is never mistaken
# for a pin. Tracked in _TMP_FILES and swept on exit; a run killed before
# that (SIGKILL can't be trapped at all) leaves one behind for the next
# run's startup sweep just below to catch instead.
#
# Sets $_LAST_TMP rather than printing the path for a caller to capture with
# $(...): that capture runs this function in a subshell, so its append to
# _TMP_FILES would land in the subshell's own copy of the array and vanish
# the moment it exits -- the EXIT trap below would then always see an empty
# array, no matter how many temp files this run actually made.
_TMP_FILES=()
_LAST_TMP=""
_new_tmp() { _LAST_TMP=$(mktemp "$PIN_DIR/.tmp.XXXXXX"); _TMP_FILES+=("$_LAST_TMP"); }
trap '((${#_TMP_FILES[@]})) && rm -f "${_TMP_FILES[@]}"' EXIT
rm -f "$PIN_DIR"/.tmp.* 2>/dev/null || true

# ---- the "currently on the clipboard" marker ---------------------------------

# Image and text need different comparisons: cliphist's preview for an image
# is a fixed placeholder ("[[ binary data ... ]]"), not the image itself, so
# matching it against the live clipboard's raw bytes as if they were the same
# kind of string never works -- an image entry's dot never lit (verified:
# wl-paste's raw PNG bytes piped through the text-normalizing sed/tr above
# obviously never equals that placeholder string). Decide once per run which
# kind the live clipboard actually is, and compare like for like.
CURRENT_IS_IMAGE=0
CURRENT=""
CURRENT_IMAGE_HASH=""

read_current_clipboard() {
  if wl-paste --list-types 2>/dev/null | grep -q '^image/'; then
    CURRENT_IS_IMAGE=1
    CURRENT_IMAGE_HASH=$(wl-paste 2>/dev/null | sha256sum | cut -d' ' -f1)
  else
    CURRENT_IS_IMAGE=0
    CURRENT=$(wl-paste --no-newline 2>/dev/null | tr -s '[:space:]' ' ' | sed 's/^ //' | head -c 200 || true)
  fi
}

# cliphist cuts text previews short and ends them in "…", so a text row is
# current when its preview (minus the "…") is a prefix of the clipboard, not
# when equal. An image row is current when its decoded bytes (image_file --
# the full decode, not the thumbnail) hash the same as the live clipboard's.
is_current() {
  local preview=$1 image_file=$2
  if (( CURRENT_IS_IMAGE )); then
    [[ -n "$image_file" && -s "$image_file" ]] || return 1
    [[ "$(sha256sum < "$image_file" | cut -d' ' -f1)" == "$CURRENT_IMAGE_HASH" ]]
  else
    [[ -n "$CURRENT" && "$CURRENT" == "${preview%…}"* ]]
  fi
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
  local number=$1 preview=$2 pinned=$3 image_file=$4 mark="  "
  is_current "$preview" "$image_file" && mark="● "
  printf '%d  %s%s%s' "$number" "$mark" "${pinned:+$PIN_ICON }" "$preview"
}

# One row per entry: kind <SEP> key <SEP> label <SEP> icon-path
#   kind  pin | hist      key  pin id | the full `cliphist list` line
#   icon  always set: a real thumbnail for an image, the placeholder for text
collect_rows() {
  local n=0 file id preview line icon rawimg
  declare -A pinned_previews=()
  declare -gA LISTED_IDS=()

  while IFS= read -r file; do
    [[ -n "$file" ]] || continue
    id=$(basename "$file" .txt)
    preview=$(head -c 200 "$file")
    pinned_previews["$preview"]=1
    n=$((n + 1))
    icon=$(pin_image "$id") || icon=""   # text: no icon -- the pane stays empty for it
    rawimg=""; [[ -n "$icon" ]] && rawimg="$PIN_DIR/$id.bin"   # full decode, for is_current
    printf 'pin%s%s%s%s%s%s\n' "$SEP" "$id" "$SEP" "$(label "$n" "$preview" 1 "$rawimg")" "$SEP" "$icon"
  done < <(ls -t "$PIN_DIR"/*.txt 2>/dev/null || true)

  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    preview=${line#*$'\t'}
    [[ -n "${pinned_previews["$preview"]:-}" ]] && continue   # already listed as a pin
    n=$((n + 1))
    icon="" rawimg=""   # text: no icon -- the pane stays empty for it
    if is_image_preview "$preview"; then
      LISTED_IDS[${line%%$'\t'*}]=1
      icon=$(history_image "$line") || icon=""
      [[ -n "$icon" ]] && rawimg="$IMAGE_CACHE/${line%%$'\t'*}"   # full decode, for is_current
    fi
    printf 'hist%s%s%s%s%s%s\n' "$SEP" "$line" "$SEP" "$(label "$n" "$preview" "" "$rawimg")" "$SEP" "$icon"
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

# A pin already has its real mime type stored (pin() writes it via `file`);
# a plain history entry has nothing of the sort, so it defaulted to
# text/plain unconditionally, even for an image -- meaning copying an image
# out of history mislabelled the clipboard as text. Harmless for text itself,
# but it made the live clipboard invisible as an image to anything checking
# its mime type afterward (is_current()'s image-hash comparison above, for
# one: it never ran, since the clipboard never looked like an image to begin
# with). Detect it the same way pin() does instead of assuming.
copy_entry() {
  local kind=$1 key=$2 mime=text/plain tmp
  if [[ "$kind" == pin ]]; then
    [[ -r "$PIN_DIR/$key.mime" ]] && mime=$(cat "$PIN_DIR/$key.mime")
    payload "$kind" "$key" | wl-copy --type "$mime"
  else
    _new_tmp; tmp=$_LAST_TMP
    payload "$kind" "$key" > "$tmp"
    mime=$(file -b --mime-type "$tmp")
    wl-copy --type "$mime" < "$tmp"
    rm -f "$tmp"
  fi
}

# A pin's id IS a content hash (see pin() below), so finding/matching a
# cliphist history line against a given pin never needs its preview text --
# matching on preview substrings let an unrelated entry with a coincidentally
# similar preview be mistaken for the pin (two images truncated to the same
# "[[ binary data ... ]]"-style text, for instance). Decodes every line, so
# it's only used from pin/unpin/delete -- explicit, infrequent actions -- not
# from collect_rows()'s per-open listing.
#   _cliphist_lines_matching <id> -- cliphist list's lines whose decoded
#   content hashes to <id>, one per line
_cliphist_lines_matching() {
  local id=$1 line
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    [[ "$(printf '%s' "$line" | cliphist decode | sha256sum | cut -c1-12)" == "$id" ]] && printf '%s\n' "$line"
  done < <(cliphist list 2>/dev/null || true)
}

# Removes a pin's cached thumbnail. thumbnail()/thumbnail_path() key off a
# hash of the *path* "$PIN_DIR/$id.bin", which nothing else ever revisits
# once the pin itself is gone -- prune_image_cache() below only walks
# $IMAGE_CACHE, the separate cliphist-history decode cache -- so without
# this a removed pin's thumbnail stays on disk forever.
_remove_pin_thumbnail() {
  rm -f "$(thumbnail_path "$PIN_DIR/$1.bin")"
}

unpin() {
  local id=$1
  # Put it back into history if it has since dropped out, so unpinning never
  # loses the item -- guarded on the .bin actually existing, so a pin whose
  # payload has gone missing still falls through to the cleanup below instead
  # of aborting the whole script right here (set -e; a missing .bin would
  # otherwise kill `cliphist store` and everything after it, including the
  # rm -f that's supposed to clear out this now-broken pin's leftovers).
  if [[ -r "$PIN_DIR/$id.bin" ]] && [[ -z "$(_cliphist_lines_matching "$id")" ]]; then
    cliphist store < "$PIN_DIR/$id.bin" || true
  fi
  rm -f "$PIN_DIR/$id.txt"   # first: this is what makes a pin "exist" in the menu
  rm -f "$PIN_DIR/$id".{bin,mime}
  _remove_pin_thumbnail "$id"
  notify clipboard "Unpinned" "Kept in history"
}

pin() {
  local line=$1 tmp id mime_tmp txt_tmp
  _new_tmp; tmp=$_LAST_TMP
  payload hist "$line" > "$tmp"
  id=$(sha256sum "$tmp" | cut -c1-12)
  if [[ -e "$PIN_DIR/$id.bin" ]]; then
    rm -f "$tmp"
    notify clipboard "Already pinned"
    return
  fi
  mv -f "$tmp" "$PIN_DIR/$id.bin"
  _new_tmp; mime_tmp=$_LAST_TMP
  file -b --mime-type "$PIN_DIR/$id.bin" > "$mime_tmp"
  mv -f "$mime_tmp" "$PIN_DIR/$id.mime"
  _new_tmp; txt_tmp=$_LAST_TMP
  printf '%s' "${line#*$'\t'}" > "$txt_tmp"
  mv -f "$txt_tmp" "$PIN_DIR/$id.txt"   # last: this is what makes it "exist" in the menu
  notify clipboard "Pinned"
}

toggle_pin() {
  if [[ "$1" == pin ]]; then unpin "$2"; else pin "$2"; fi
}

delete_entry() {
  local kind=$1 key=$2
  if [[ "$kind" == pin ]]; then
    rm -f "$PIN_DIR/$key.txt"   # first: this is what makes a pin "exist" in the menu
    rm -f "$PIN_DIR/$key".{bin,mime}
    _remove_pin_thumbnail "$key"
    _cliphist_lines_matching "$key" | cliphist delete 2>/dev/null || true
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
    if incognito_on; then
      incognito_notice
      continue
    fi

    read_current_clipboard
    rows=$(collect_rows)
    if [[ -z "$rows" ]]; then
      notify clipboard "Clipboard is empty"
      exit 0
    fi

    rc=0
    index=$(printf '%s\n' "$rows" | menu_lines |
      rofi -dmenu -i -format i -theme preview -mesg "$(footer)" \
           -kb-custom-1 "Alt+p" -kb-custom-2 "Alt+d" -kb-custom-3 "Alt+w" \
           -kb-custom-4 "Alt+q") || rc=$?

    if (( rc == KEY_WIPE )); then wipe_history; continue; fi
    if (( rc == KEY_INCOGNITO )); then toggle_incognito; continue; fi
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
