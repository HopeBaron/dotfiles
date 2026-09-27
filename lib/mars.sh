#!/usr/bin/env bash
# Shared paths and helpers for bin/ and the menu scripts in
# config/.config/hypr/scripts/. Source it; it defines nothing that runs.

# The repo, found from this file's real location -- scripts reach it through
# stow symlinks, so their own path would point into ~/.config instead.
MARS_REPO=$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)
MARS_BIN="$MARS_REPO/bin"
MARS_WALLPAPER_DIR="$MARS_REPO/wallpapers"

MARS_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mars"   # choices that persist
MARS_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/mars"          # safe to delete

# Desktop notification; a no-op where notify-send isn't installed.
#   notify <app-name> <summary> [body]
notify() {
  command -v notify-send >/dev/null || return 0
  notify-send -a "$1" "$2" "${3:-}" || true
}

# Path to a cached, downscaled copy of an image, (re)made when the source is
# newer. rofi decodes icons at full size, so previewing multi-megapixel
# wallpapers directly makes menus visibly slow to open.
#   thumbnail <image> [max-edge-px]
thumbnail() {
  local src=$1 size=${2:-512} out
  out=$(thumbnail_path "$src" "$size")
  if [[ ! -s "$out" || "$src" -nt "$out" ]]; then
    mkdir -p "$(dirname "$out")"
    magick "$src"'[0]' -auto-orient -thumbnail "${size}x${size}>" "$out" 2>/dev/null || return 1
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
