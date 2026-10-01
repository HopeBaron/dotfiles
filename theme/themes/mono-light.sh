#!/usr/bin/env bash
# Monochromatic Light -- the inverse of mono-dark.sh: true white and true
# black, no hue anywhere. Same trade-off applies (see mono-dark.sh's header):
# the seven "accent" names are brightness steps, not colours, kept only so
# the accent picker still has seven distinct rows.
#
# A theme file only has to set THEME_MODE and the palette variables below
# (bare hex, no '#'). Everything else -- accent, text-on-accent, GTK/icon
# variants -- is derived from these by theme/lib.sh.

THEME_MODE=light

# Backgrounds: BG0 is true white; each step down dims off it slightly so
# surfaces (toolbars, borders) stay readable without ever tinting.
BG_DIM=ececec
BG0=ffffff
BG1=f0f0f0
BG2=f0f0f0
BG3=e0e0e0
BG4=e0e0e0
BG5=cccccc

# Foregrounds: FG0 is body text, kept just off pure black for the light-mode
# equivalent of avoiding halation; FG1 is true black, for maximum-emphasis
# text (headings, the odd "make this pop" case).
FG0=1a1a1a
FG1=000000

# Greys: muted text. Lightness order flips vs. mono-dark.sh (GREY0 lightest,
# GREY2 darkest), matching how the Gruvbox palettes invert greys per mode.
GREY0=a3a3a3
GREY1=838383
GREY2=636363

# "Accents": no colour, just seven brightness steps, all kept in a midtone
# band clearly apart from FG0 (1a1a1a) as well as from BG0 (ffffff).
#
# A near-black accent looks truest to "monochrome" at first, but several
# real apps (confirmed in Dolphin/Breeze's item-view hover) paint a
# highlight's background in the raw accent colour while keeping the NORMAL
# text colour on top of it, not the computed ACCENT_FG -- they only handle
# contrast for a true "selected" state, not a "hovered" one. FG0 sitting
# only ~25 levels from an accent like 333333 made that hover fill read as
# near-black text on near-black background. Every step below stays >=100
# levels from FG0's 26, so that pairing stays legible even when an app
# never asks theme_derive() for ACCENT_FG at all.
RED=b0b0b0
ORANGE=a5a5a5
YELLOW=9a9a9a
GREEN=8f8f8f
AQUA=848484
BLUE=797979
PURPLE=6e6e6e
