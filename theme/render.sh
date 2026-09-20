#!/usr/bin/env bash
# Render every theme/templates/* into its app config, substituting palette vars.
# Templates use ${BG0} style placeholders. Run after editing theme/palette.sh.
set -euo pipefail
here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repo=$(dirname "$here")

set -a; . "$here/palette.sh"; set +a

render() { envsubst < "$here/templates/$1" > "$repo/config/.config/$2"; echo "  rendered $2"; }

echo "Rendering Gruvbox Material (dark/medium/material):"
render hypr-colors.lua   hypr/colors.lua
render kitty-colors.conf kitty/colors.conf
render wofi-style.css    wofi/style.css
echo "Done. Reload: hyprctl reload  /  kitty @ load-config"
