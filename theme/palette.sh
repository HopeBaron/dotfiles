#!/usr/bin/env bash
# Gruvbox Material - dark, background=medium, foreground=material
#
# SINGLE SOURCE OF TRUTH for every colour in this repo.
# Do not hand-write hex values in any app config; add a template in
# theme/templates/ and run ./theme/render.sh instead.
#
# Values transcribed verbatim from sainnhe/gruvbox-material:
#   autoload/gruvbox_material.vim  (palette table)
#   doc/gruvbox-material.txt       (background/foreground options)
# `background` (hard|medium|soft) sets bg* only.
# `foreground` (material|mix|original) sets accents only. The two are independent.

# Backgrounds (medium)
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

# Accents (material)
RED=ea6962
ORANGE=e78a4e
YELLOW=d8a657
GREEN=a9b665
AQUA=89b482
BLUE=7daea3
PURPLE=d3869b
