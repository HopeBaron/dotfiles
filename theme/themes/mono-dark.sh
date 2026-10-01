#!/usr/bin/env bash
# Monochromatic Dark -- true black and true white, no hue anywhere. Every
# value below is a shade of grey; the seven "accent" names are kept only so
# the existing accent picker still has seven distinct rows to choose from --
# they're brightness steps, not colours, so pick whichever contrast you want.
#
# Trade-off worth knowing: a true monochrome theme can't lean on colour for
# meaning, so destructive (red) vs. positive (green) states lose their usual
# hue cue and read only by brightness/position -- fine for this theme's
# purpose, but not colourblind-equivalent to the Gruvbox palettes.
#
# A theme file only has to set THEME_MODE and the palette variables below
# (bare hex, no '#'). Everything else -- accent, text-on-accent, GTK/icon
# variants -- is derived from these by theme/lib.sh.

THEME_MODE=dark

# Backgrounds: BG0 is true black; each step up lifts off it slightly so
# surfaces (toolbars, borders) stay readable without ever tinting.
BG_DIM=000000
BG0=000000
BG1=141414
BG2=141414
BG3=262626
BG4=262626
BG5=3d3d3d

# Foregrounds: FG0 is body text, kept just off pure white to avoid the
# halation white-on-black causes; FG1 is true white, for the rare place that
# wants maximum emphasis (headings, the odd "make this pop" case).
FG0=e8e8e8
FG1=ffffff

# Greys: muted text, ascending brightness.
GREY0=5c5c5c
GREY1=7a7a7a
GREY2=9c9c9c

# "Accents": no colour, just seven brightness steps, all kept in a midtone
# band clearly apart from FG0 (e8e8e8) as well as from BG0 (000000).
#
# A near-white accent looks truest to "monochrome" at first, but several
# real apps (confirmed in Dolphin/Breeze's item-view hover, see
# mono-light.sh) paint a highlight's background in the raw accent colour
# while keeping the NORMAL text colour on top of it, not the computed
# ACCENT_FG -- they only handle contrast for a true "selected" state, not a
# "hovered" one. The old ramp (999999..ffffff) sat right on top of FG0's
# e8e8e8, so that hover fill read as near-white text on a near-white
# background. Every step below stays a good distance from FG0, so that
# pairing stays legible even when an app never asks theme_derive() for
# ACCENT_FG at all.
RED=a0a0a0
ORANGE=969696
YELLOW=8c8c8c
GREEN=828282
AQUA=787878
BLUE=6e6e6e
PURPLE=646464
