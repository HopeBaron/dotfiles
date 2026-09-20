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
echo "Done. Reload: hyprctl reload  /  kitty @ load-config"
