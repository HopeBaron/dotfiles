#!/usr/bin/env bash
# Gruvbox Material palette, transcribed verbatim from sainnhe/gruvbox-material
# (autoload/gruvbox_material.vim, gruvbox_material#get_palette).
#
# The scheme has three independent axes, exactly as in the Vim plugin:
#   mode        dark | light              -> which half of every table below
#   background  hard | medium | soft      -> sets BG_DIM and BG0..BG5 only
#   foreground  material | mix | original -> sets FG0/FG1 and the accents only
# Greys depend on the mode alone.
#
# Usage (sourced):  gruvbox_material_palette <mode> <background> <foreground>
# Sets and exports BG_DIM BG0..BG5 FG0 FG1 GREY0..GREY2 and the seven accents
# (RED ORANGE YELLOW GREEN AQUA BLUE PURPLE), as bare hex without '#'.

gruvbox_material_palette() {
  local mode=$1 background=$2 foreground=$3

  case "$mode/$background" in
    dark/hard)    _gm_set_backgrounds 141617 1d2021 282828 282828 3c3836 3c3836 504945 ;;
    dark/medium)  _gm_set_backgrounds 1b1b1b 282828 32302f 32302f 45403d 45403d 5a524c ;;
    dark/soft)    _gm_set_backgrounds 252423 32302f 3c3836 3c3836 504945 504945 665c54 ;;
    light/hard)   _gm_set_backgrounds f3eac7 f9f5d7 f5edca f3eac7 f2e5bc eee0b7 ebdbb2 ;;
    light/medium) _gm_set_backgrounds f2e5bc fbf1c7 f4e8be f2e5bc eee0b7 e5d5ad ddccab ;;
    light/soft)   _gm_set_backgrounds ebdbb2 f2e5bc eddeb5 ebdbb2 e6d5ae dac9a5 d5c4a1 ;;
    *) echo "gruvbox_material_palette: unknown mode/background '$mode/$background'" >&2; return 1 ;;
  esac

  #                                      fg0    fg1    red    orange yellow green  aqua   blue   purple
  case "$mode/$foreground" in
    dark/material)  _gm_set_foregrounds  d4be98 ddc7a1 ea6962 e78a4e d8a657 a9b665 89b482 7daea3 d3869b ;;
    dark/mix)       _gm_set_foregrounds  e2cca9 e2cca9 f2594b f28534 e9b143 b0b846 8bba7f 80aa9e d3869b ;;
    dark/original)  _gm_set_foregrounds  ebdbb2 ebdbb2 fb4934 fe8019 fabd2f b8bb26 8ec07c 83a598 d3869b ;;
    light/material) _gm_set_foregrounds  654735 4f3829 c14a4a c35e0a b47109 6c782e 4c7a5d 45707a 945e80 ;;
    light/mix)      _gm_set_foregrounds  514036 514036 af2528 b94c07 b4730e 72761e 477a5b 266b79 924f79 ;;
    light/original) _gm_set_foregrounds  3c3836 3c3836 9d0006 af3a03 b57614 79740e 427b58 076678 8f3f71 ;;
    *) echo "gruvbox_material_palette: unknown mode/foreground '$mode/$foreground'" >&2; return 1 ;;
  esac

  case "$mode" in
    dark)  export GREY0=7c6f64 GREY1=928374 GREY2=a89984 ;;
    light) export GREY0=a89984 GREY1=928374 GREY2=7c6f64 ;;
  esac
}

_gm_set_backgrounds() {
  export BG_DIM=$1 BG0=$2 BG1=$3 BG2=$4 BG3=$5 BG4=$6 BG5=$7
}

_gm_set_foregrounds() {
  export FG0=$1 FG1=$2 RED=$3 ORANGE=$4 YELLOW=$5 GREEN=$6 AQUA=$7 BLUE=$8 PURPLE=$9
}
