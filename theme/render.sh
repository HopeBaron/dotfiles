#!/usr/bin/env bash
# Render every theme/templates/* into its app config, substituting palette vars.
# Templates use ${BG0} style placeholders. Run after editing theme/palette.sh.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

set -a; . "$here/palette.sh"; set +a

# Substitute ONLY the palette names. Bare `envsubst` would also expand $HOME
# and friends, baking this machine's paths into committed files.
vars=$(sed -n 's/^\([A-Z0-9_]\+\)=.*/${\1}/p' "$here/palette.sh" | tr '\n' ' ')

render() { envsubst "$vars" < "$here/templates/$1" > "$repo/config/.config/$2"; echo "  rendered $2"; }

# qt6ct.conf needs an absolute path to the colour scheme (qt6ct does not
# expand ~), which must resolve correctly on whatever machine this runs on --
# not the machine that committed it. Unlike the general `render`, this widens
# the whitelist to include ${HOME}, deliberately and only for this one file:
# render.sh always runs ON the deploying machine itself, so the value baked in
# is that machine's real $HOME, not a stray one shipped in from git.
render_with_home() { envsubst "$vars \${HOME}" < "$here/templates/$1" > "$repo/config/.config/$2"; echo "  rendered $2"; }

# For files that are not under ~/.config (system/ is copied into / by install.sh).
render_repo() { envsubst "$vars" < "$here/templates/$1" > "$repo/$2"; echo "  rendered $2"; }

echo "Rendering Gruvbox Material (dark/medium/material):"
render hypr-colors.lua   hypr/colors.lua
render kitty-colors.conf kitty/colors.conf
render rofi-theme.rasi   rofi/gruvbox-material.rasi
render waybar-config.jsonc waybar/config.jsonc
render waybar-style.css  waybar/style.css
render swaync-style.css  swaync/style.css
render yazi-theme.toml   yazi/theme.toml
render qt6ct-colors.conf qt6ct/colors/gruvbox-material.conf
render_with_home qt6ct.conf qt6ct/qt6ct.conf
render_with_home qt-style.qss qt6ct/qss/gruvbox-material.qss
render qt-tab-close.svg       qt6ct/qss/tab-close.svg
render qt-tab-close-hover.svg qt6ct/qss/tab-close-hover.svg
render hyprlock.conf     hypr/hyprlock.conf
render_repo sddm-theme.conf system/sddm/theme/theme.conf
render_repo gtk3.css config/.local/share/themes/Gruvbox-Material/gtk-3.0/gtk.css
# Plain (non-libadwaita) GTK4 apps like pavucontrol load the theme's gtk-4.0/.
# GTK4 keeps GTK3's widget node names, so the same rules apply; only the base
# stylesheet they recolour differs.
mkdir -p "$repo/config/.local/share/themes/Gruvbox-Material/gtk-4.0"
sed 's|theme/Adwaita/gtk-contained-dark.css|theme/Default/Default-dark.css|' \
  "$repo/config/.local/share/themes/Gruvbox-Material/gtk-3.0/gtk.css" \
  > "$repo/config/.local/share/themes/Gruvbox-Material/gtk-4.0/gtk.css"
echo "  rendered config/.local/share/themes/Gruvbox-Material/gtk-4.0/gtk.css"
render gtk4.css          gtk-4.0/gtk.css
render kdeglobals        kdeglobals
# KF6 apps look the scheme up BY NAME ([General] ColorScheme) and fall back to
# Breeze if no such .colors file exists -- kdeglobals alone is not enough.
render_repo kdeglobals config/.local/share/color-schemes/GruvboxMaterial.colors
echo "Done. Reload: hyprctl reload  /  kitty @ load-config"
