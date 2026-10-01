#!/usr/bin/env bash
# Render every template in theme/templates/ into the config it belongs to,
# for the saved theme + accent (see theme/lib.sh). Normally run through
# `mars-theme`, which also pushes the result into running apps.
#
# Templates use ${VAR} placeholders from MARS_TEMPLATE_VARS only; outputs are
# gitignored, since they change with every theme switch.
set -euo pipefail

# shellcheck source=lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

readonly TEMPLATES="$MARS_THEME_DIR/templates"
readonly GTK_THEME_DIR="config/.local/share/themes/Gruvbox-Material"

# template                    -> output (relative to the repo root)
readonly RENDER_TABLE=(
  "hypr-colors.lua            config/.config/hypr/colors.lua"
  "hyprlock.conf              config/.config/hypr/hyprlock.conf"
  "kitty-colors.conf          config/.config/kitty/colors.conf"
  "rofi-theme.rasi            config/.config/rofi/gruvbox-material.rasi"
  "waybar-config.jsonc        config/.config/waybar/config.jsonc"
  "waybar-style.css           config/.config/waybar/style.css"
  "swaync-style.css           config/.config/swaync/style.css"
  "swayosd-style.css          config/.config/swayosd/style.css"
  "yazi-theme.toml            config/.config/yazi/theme.toml"
  "qt6ct-colors.conf          config/.config/qt6ct/colors/gruvbox-material.conf"
  "qt-tab-close.svg           config/.config/qt6ct/qss/tab-close.svg"
  "qt-tab-close-hover.svg     config/.config/qt6ct/qss/tab-close-hover.svg"
  "kdeglobals                 config/.config/kdeglobals"
  "kdeglobals                 config/.local/share/color-schemes/GruvboxMaterial.colors"
  "gtk4-settings.ini          config/.config/gtk-4.0/settings.ini"
  "gtk4-libadwaita.css        config/.config/gtk-4.0/gtk.css"
  "sddm-theme.conf            system/sddm/theme/theme.conf"
)

# These embed absolute paths (qt6ct expands neither ~ nor relative paths), so
# they also get ${HOME} -- this machine's, since render always runs on the
# machine being themed.
readonly RENDER_WITH_HOME_TABLE=(
  "qt6ct.conf                 config/.config/qt6ct/qt6ct.conf"
  "qt-style.qss               config/.config/qt6ct/qss/gruvbox-material.qss"
)

envsubst_vars() {
  local name out=""
  for name in "${MARS_TEMPLATE_VARS[@]}" "$@"; do out+="\${$name} "; done
  echo "$out"
}

# Writes under $MARS_REPO by default -- the live, symlinked-into-$HOME config
# -- but mars-theme-export points this at a scratch directory instead, to
# render a theme that isn't the active one without touching anything live.
render_file() {
  local template=$1 output=$2 vars=$3 root=${MARS_RENDER_ROOT:-$MARS_REPO}
  mkdir -p "$(dirname "$root/$output")"
  envsubst "$vars" < "$TEMPLATES/$template" > "$root/$output"
  echo "  $output"
}

render_table() {
  local vars=$1; shift
  local row template output
  for row in "$@"; do
    read -r template output <<<"$row"
    render_file "$template" "$output" "$vars"
  done
}

# One stylesheet serves both GTK versions: it recolours GTK's own base theme,
# which lives at a different resource path (and name) in GTK3 and GTK4.
render_gtk_theme() {
  local vars
  vars=$(envsubst_vars GTK_BASE_URL)
  export GTK_BASE_URL
  GTK_BASE_URL="resource:///org/gtk/libgtk/theme/Adwaita/$GTK3_BASE_CSS"
  render_file gtk-theme.css "$GTK_THEME_DIR/gtk-3.0/gtk.css" "$vars"
  GTK_BASE_URL="resource:///org/gtk/libgtk/theme/Default/$GTK4_BASE_CSS"
  render_file gtk-theme.css "$GTK_THEME_DIR/gtk-4.0/gtk.css" "$vars"
}

# Everything except theme_activate itself, so mars-theme-export can render an
# arbitrary theme/accent (already loaded+derived) into MARS_RENDER_ROOT
# without going through the saved state at all.
render_all() {
  render_table "$(envsubst_vars)" "${RENDER_TABLE[@]}"
  render_table "$(envsubst_vars HOME)" "${RENDER_WITH_HOME_TABLE[@]}"
  render_gtk_theme
}

main() {
  theme_activate
  echo "Rendering $THEME_LABEL, accent $ACCENT_SPEC (#$ACCENT):"
  render_all
}

# Sourced by mars-theme-export to reuse these functions -- only run main when
# executed directly.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
