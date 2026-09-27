#!/usr/bin/env bash
# GruvMoon -- this setup's original hand-kept palette.
#
# Identical to Gruvbox Material dark / medium / material today, but kept as
# its own file on purpose: it is the "house" theme, free to drift from the
# upstream values without touching theme/gruvbox-material.sh.
#
# A theme file only has to set THEME_MODE and the palette variables below
# (bare hex, no '#'). Everything else -- accent, text-on-accent, GTK/icon
# variants -- is derived from these by theme/lib.sh.

THEME_MODE=dark

# Backgrounds
BG_DIM=1b1b1b
BG0=282828
BG1=32302f
BG2=32302f
BG3=45403d
BG4=45403d
BG5=5a524c

# Foregrounds
FG0=d4be98
FG1=ddc7a1

# Greys
GREY0=7c6f64
GREY1=928374
GREY2=a89984

# Accents
RED=ea6962
ORANGE=e78a4e
YELLOW=d8a657
GREEN=a9b665
AQUA=89b482
BLUE=7daea3
PURPLE=d3869b
