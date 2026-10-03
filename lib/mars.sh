#!/usr/bin/env bash
# Shared paths and helpers for bin/ and the menu scripts in
# config/.config/hypr/scripts/. Source it; apart from creating the state and
# cache dirs below, it defines nothing that runs.

# The repo, found from this file's real location -- scripts reach it through
# stow symlinks, so their own path would point into ~/.config instead.
MARS_REPO=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
MARS_BIN="$MARS_REPO/bin"
MARS_WALLPAPER_DIR="$MARS_REPO/wallpapers"

MARS_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mars"   # choices that persist
MARS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mars"          # safe to delete

# Created up front so no script can trip over a missing dir on a fresh
# install -- the first-login hyprpaper failure was exactly that.
mkdir -p "$MARS_STATE_DIR" "$MARS_CACHE_DIR"

# Desktop notification; a no-op where notify-send isn't installed.
#   notify <app-name> <summary> [body]
notify() {
  command -v notify-send >/dev/null || return 0
  notify-send -a "$1" "$2" "${3:-}" || true
}

# A user dir (PICTURES, VIDEOS, ...) from xdg-user-dirs, or <fallback> when
# that isn't installed or the dir isn't configured -- xdg-user-dir prints
# $HOME itself for an unconfigured one.
#   user_dir <XDG-NAME> <fallback>
user_dir() {
  local dir=""
  command -v xdg-user-dir >/dev/null && dir=$(xdg-user-dir "$1" 2>/dev/null || true)
  [[ -n "$dir" && "$dir" != "$HOME" ]] || dir=$2
  echo "$dir"
}

# Path to a cached, downscaled copy of an image, (re)made when the source is
# newer. rofi decodes icons at full size, so previewing multi-megapixel
# wallpapers directly makes menus visibly slow to open.
#   thumbnail <image> [max-edge-px]
thumbnail() {
  local src=$1 size=${2:-512} out tmp
  out=$(thumbnail_path "$src" "$size")
  if [[ ! -s "$out" || "$src" -nt "$out" ]]; then
    mkdir -p "$(dirname "$out")"
    # Same directory as $out, not /tmp: the final `mv` has to be a rename on
    # the same filesystem to be atomic, and a killed `magick` must not leave
    # a truncated file sitting at $out -- `[[ -s "$out" ]]` above would then
    # treat that corrupt file as a validly cached thumbnail forever.
    tmp="$out.tmp.$$"
    magick "$src"'[0]' -auto-orient -thumbnail "${size}x${size}>" "$tmp" 2>/dev/null \
      || { rm -f "$tmp"; return 1; }
    mv -f "$tmp" "$out"
  fi
  echo "$out"
}

# Where thumbnail() caches <image> -- also used to delete it with the source.
#   thumbnail_path <image> [max-edge-px]
thumbnail_path() {
  local key
  key=$(printf '%s' "$1" | sha1sum | cut -c1-16)
  echo "$MARS_CACHE_DIR/thumbnails/${2:-512}/$key.png"
}

# ---- theme menus ---------------------------------------------------------
# Shared by every rofi menu that lists or bulk-applies to themes
# (rofi-theme.sh, rofi-theme-picker.sh, rofi-accent.sh, rofi-wallpaper.sh),
# so `mars-theme`'s output format only needs parsing in one place.

# Fills the arrays named by $1 (ids) and $2 (labels) from `mars-theme list`'s
# "id<TAB>label" lines.
#   mars_theme_list <ids-array-name> <labels-array-name>
mars_theme_list() {
  local -n ids_ref=$1 labels_ref=$2
  local id label
  while IFS=$'\t' read -r id label; do
    ids_ref+=("$id"); labels_ref+=("$label")
  done < <("$MARS_BIN/mars-theme" list)
}

# The id of the currently active theme.
mars_theme_current() {
  "$MARS_BIN/mars-theme" current | awk -F'\t' '$1 == "theme" { print $2 }'
}

# Opens rofi-theme-picker.sh and fills the array named by $1 with the theme
# ids it prints. Exits the CALLING SCRIPT with status 0 if none came back --
# mapfile itself succeeds regardless of the picker's own exit status
# (Escape/cancel just prints nothing), so this emptiness check is what
# actually catches that case; every caller treats "nothing picked" as
# "nothing to do", so doing it here once is safe.
#   pick_themes <out-array-name>
pick_themes() {
  local -n out_ref=$1
  mapfile -t out_ref < <("$MARS_REPO/config/.config/hypr/scripts/rofi-theme-picker.sh")
  (( ${#out_ref[@]} )) || exit 0
}
