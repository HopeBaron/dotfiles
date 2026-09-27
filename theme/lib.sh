#!/usr/bin/env bash
# Theme library: which themes exist, how one is loaded, and where the user's
# choice is saved. Sourced by theme/render.sh, bin/mars-theme and the rofi
# menus, so there is exactly one definition of each of these.
#
# Vocabulary
#   theme     a complete palette plus a mode (dark|light). Either a hand-kept
#             file in theme/themes/<id>.sh (e.g. gruvmoon) or a computed
#             Gruvbox Material variant, id gruvbox-material-<mode>-<bg>-<fg>.
#   accent    the one highlight colour (selection, focus, active tab...). A
#             palette colour name, resolved per theme so it stays in key on
#             light themes, or a fixed custom hex.
#   state     the current choice of theme + accent, in $MARS_STATE_FILE.
#             Never touches the theme *definitions* above -- those are repo
#             files; state is which one, and which accent, is picked right now.
#   override  a specific theme's OWN remembered accent and/or wallpaper, in
#             $MARS_OVERRIDE_DIR/<id>.env. Absent = that theme has never been
#             customized, so it just carries forward whatever the current
#             accent/wallpaper already is when you switch to it. Present =
#             switching to that theme re-applies its own remembered choice.
#             Also never touches the theme definitions -- same reason.

# shellcheck source=../lib/mars.sh
. "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../lib/mars.sh"   # MARS_REPO, MARS_STATE_DIR

MARS_THEME_DIR="$MARS_REPO/theme"
MARS_STATE_FILE="$MARS_STATE_DIR/theme.env"
MARS_OVERRIDE_DIR="$MARS_STATE_DIR/themes"

readonly MARS_DEFAULT_THEME=gruvmoon
readonly MARS_DEFAULT_ACCENT=green
readonly MARS_ACCENT_NAMES=(red orange yellow green aqua blue purple)

readonly GM_MODES=(dark light)
readonly GM_BACKGROUNDS=(hard medium soft)
readonly GM_FOREGROUNDS=(material mix original)

# Every variable a template may reference. render.sh passes exactly this list
# to envsubst, so an unrelated $VAR in a template (or $HOME) is left alone.
readonly MARS_TEMPLATE_VARS=(
  BG_DIM BG0 BG1 BG2 BG3 BG4 BG5 FG0 FG1 GREY0 GREY1 GREY2
  RED ORANGE YELLOW GREEN AQUA BLUE PURPLE
  ACCENT ACCENT_FG SHADOW
  THEME_ID THEME_LABEL THEME_MODE
  GTK3_BASE_CSS GTK4_BASE_CSS GTK_PREFER_DARK COLOR_SCHEME ICON_THEME
)

# shellcheck source=gruvbox-material.sh
. "$MARS_THEME_DIR/gruvbox-material.sh"

# ---- themes ------------------------------------------------------------------

theme_list() {
  local file mode bg fg
  for file in "$MARS_THEME_DIR"/themes/*.sh; do
    basename "$file" .sh
  done
  for mode in "${GM_MODES[@]}"; do
    for bg in "${GM_BACKGROUNDS[@]}"; do
      for fg in "${GM_FOREGROUNDS[@]}"; do
        echo "gruvbox-material-$mode-$bg-$fg"
      done
    done
  done
}

theme_exists() {
  # Not `theme_list | grep -q`: grep exits at the first match, theme_list then
  # dies of SIGPIPE, and under `set -o pipefail` that reads as "not found".
  local id
  while read -r id; do
    [[ "$id" == "$1" ]] && return 0
  done < <(theme_list)
  return 1
}

# gruvmoon -> "GruvMoon"; gruvbox-material-dark-medium-material ->
# "Gruvbox Material · Dark · Medium · Material"
theme_label() {
  local id=$1 rest
  case "$id" in
    gruvmoon) echo "GruvMoon" ;;
    gruvbox-material-*)
      rest=${id#gruvbox-material-}
      echo "Gruvbox Material · $(_capitalize_words "${rest//-/ }" | sed 's/ / · /g')"
      ;;
    *) _capitalize_words "${id//-/ }" ;;
  esac
}

# Loads a theme's palette and THEME_MODE into the (exported) environment.
theme_load() {
  local id=$1 spec mode bg fg
  theme_exists "$id" || { echo "unknown theme: $id" >&2; return 1; }

  if [[ -f "$MARS_THEME_DIR/themes/$id.sh" ]]; then
    set -a
    # shellcheck source=/dev/null
    . "$MARS_THEME_DIR/themes/$id.sh"
    set +a
  else
    spec=${id#gruvbox-material-}
    IFS=- read -r mode bg fg <<<"$spec"
    gruvbox_material_palette "$mode" "$bg" "$fg" || return 1
    export THEME_MODE=$mode
  fi

  export THEME_ID=$id
  THEME_LABEL=$(theme_label "$id")
  export THEME_LABEL
}

# ---- accent ------------------------------------------------------------------

accent_is_name() {
  local name
  for name in "${MARS_ACCENT_NAMES[@]}"; do
    [[ "$1" == "$name" ]] && return 0
  done
  return 1
}

accent_is_hex() {
  [[ "$1" =~ ^#?[0-9a-fA-F]{6}$ ]]
}

# Canonical stored form: a palette name, or "#rrggbb" in lower case.
accent_normalize() {
  local spec=${1,,}
  if accent_is_name "$spec"; then
    echo "$spec"
  elif accent_is_hex "$spec"; then
    echo "#${spec#\#}"
  else
    return 1
  fi
}

# Bare hex for an accent spec, against the currently loaded palette.
accent_hex() {
  local spec=$1
  if accent_is_name "$spec"; then
    local var=${spec^^}
    echo "${!var}"
  else
    echo "${spec#\#}"
  fi
}

# ---- derived values ----------------------------------------------------------

# Perceived brightness of a bare hex colour, 0..255.
_luma() {
  local hex=$1
  echo $(( (299 * 16#${hex:0:2} + 587 * 16#${hex:2:2} + 114 * 16#${hex:4:2}) / 1000 ))
}

# Everything templates need beyond the raw palette. Call after theme_load.
theme_derive() {
  local accent_spec=$1

  export ACCENT
  ACCENT=$(accent_hex "$accent_spec")

  # Text drawn ON the accent (selected row, active tab, primary button) must
  # contrast with the accent itself, whatever colour the user picked -- so
  # pick the darker or lighter end of the palette by the accent's brightness.
  local dark_end light_end
  if [[ "$THEME_MODE" == dark ]]; then dark_end=$BG0; light_end=$FG0
  else                                dark_end=$FG1; light_end=$BG0
  fi
  export ACCENT_FG
  if (( $(_luma "$ACCENT") > 140 )); then ACCENT_FG=$dark_end; else ACCENT_FG=$light_end; fi

  if [[ "$THEME_MODE" == dark ]]; then
    export GTK3_BASE_CSS=gtk-contained-dark.css GTK4_BASE_CSS=Default-dark.css
    export GTK_PREFER_DARK=1 COLOR_SCHEME=prefer-dark ICON_THEME=Gruvbox-Plus-Dark
    export SHADOW=$BG_DIM
  else
    export GTK3_BASE_CSS=gtk-contained.css GTK4_BASE_CSS=Default-light.css
    export GTK_PREFER_DARK=0 COLOR_SCHEME=prefer-light ICON_THEME=Gruvbox-Plus-Light
    # A light theme's darkest background is still near-white: useless as a
    # shadow. Use the text colour instead, at the same alpha.
    export SHADOW=$FG1
  fi
}

# ---- per-theme overrides ------------------------------------------------------
#
# One small file per customized theme, $MARS_OVERRIDE_DIR/<id>.env, holding
# whichever of ACCENT= / WALLPAPER= that theme has been explicitly given. A
# theme with neither is not customized and has no file at all -- theme_list
# still lists it normally, it just carries forward whatever is already active.

_override_file() { echo "$MARS_OVERRIDE_DIR/$1.env"; }

# The value of KEY in theme <id>'s override file, or empty if unset/absent.
_override_get() {
  local id=$1 key=$2 file
  file=$(_override_file "$id")
  [[ -r "$file" ]] || return 0
  sed -n "s/^$key=//p" "$file" | tail -n1
}

# Sets KEY=VALUE in theme <id>'s override file, preserving its other key.
_override_set() {
  local id=$1 key=$2 value=$3 file tmp
  file=$(_override_file "$id")
  mkdir -p "$MARS_OVERRIDE_DIR"
  tmp=$(mktemp)
  # grep -v exits 1 (not an error here) when the file's only line matched --
  # e.g. replacing a theme's only-ever-set key -- which would otherwise kill
  # the whole script under `set -e`.
  [[ -f "$file" ]] && { grep -v "^$key=" "$file" > "$tmp" || true; }
  printf '%s=%s\n' "$key" "$value" >> "$tmp"
  mv "$tmp" "$file"
}

# Removes KEY from theme <id>'s override file. Deletes the file once it has
# neither key left, so an untouched theme goes back to having no file at all.
_override_unset() {
  local id=$1 key=$2 file tmp
  file=$(_override_file "$id")
  [[ -f "$file" ]] || return 0
  tmp=$(mktemp)
  grep -v "^$key=" "$file" > "$tmp" || true
  if [[ -s "$tmp" ]]; then mv "$tmp" "$file"; else rm -f "$tmp" "$file"; fi
}

theme_get_accent()    { _override_get   "$1" ACCENT; }
theme_set_accent()    { _override_set   "$1" ACCENT "$2"; }
theme_reset_accent()  { _override_unset "$1" ACCENT; }

theme_get_wallpaper()   { _override_get   "$1" WALLPAPER; }
theme_set_wallpaper()   { _override_set   "$1" WALLPAPER "$2"; }
theme_reset_wallpaper() { _override_unset "$1" WALLPAPER; }

# ---- saved state -------------------------------------------------------------

# Sets THEME and ACCENT from the state file, falling back to the defaults for
# anything missing or no longer valid (e.g. a deleted theme file).
state_load() {
  THEME=$MARS_DEFAULT_THEME
  ACCENT_SPEC=$MARS_DEFAULT_ACCENT
  if [[ -r "$MARS_STATE_FILE" ]]; then
    local key value
    while IFS='=' read -r key value; do
      case "$key" in
        THEME)  theme_exists "$value" && THEME=$value ;;
        ACCENT) value=$(accent_normalize "$value") && ACCENT_SPEC=$value ;;
      esac
    done < "$MARS_STATE_FILE"
  fi
}

state_save() {
  mkdir -p "$MARS_STATE_DIR"
  printf 'THEME=%s\nACCENT=%s\n' "$1" "$2" > "$MARS_STATE_FILE"
}

# Loads the saved theme and derives everything from it: the one-call entry
# point for anything that needs the current colours.
theme_activate() {
  state_load
  theme_load "$THEME"
  theme_derive "$ACCENT_SPEC"
}

# ---- helpers -----------------------------------------------------------------

_capitalize_words() {
  local word out=()
  for word in $1; do out+=("${word^}"); done
  echo "${out[*]}"
}
