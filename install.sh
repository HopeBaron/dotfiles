#!/usr/bin/env bash
# Deploy this Hyprland setup.
#
# Baseline is an EndeavourOS install: its installer already provides the base
# system, the NVIDIA driver, the display manager and the audio/network
# services, so none of that is repeated here.
#
#   ./install.sh              install packages, render colours, stow configs
#   ./install.sh --no-deploy  skip stow (packages only)
#
# Safe to re-run; every step is idempotent.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
deploy=1

for arg in "$@"; do
  case "$arg" in
    --no-deploy) deploy=0 ;;
    -h|--help)   sed -n '2,11p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '\n\033[1;33m==>\033[0m %s\n' "$1"; }

# Strip comments and blanks from a manifest.
manifest() { sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$repo/packages/$1"; }

install_pkgs() {
  local file=$1 pkgs
  mapfile -t pkgs < <(manifest "$file")
  [ "${#pkgs[@]}" -eq 0 ] && return 0
  say "Installing from packages/$file (${#pkgs[@]} packages)"
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

[ "$(id -u)" -eq 0 ] && { echo "Run as your normal user, not root." >&2; exit 1; }

# Full upgrade, never a bare -Sy: refreshing the database without upgrading
# leaves you installing packages built against libraries you do not have.
say "Updating the system"
sudo pacman -Syu --noconfirm

# tools.txt first: it carries stow and gettext, which the deploy steps below
# call. EndeavourOS ships neither.
install_pkgs tools.txt
install_pkgs desktop.txt

# WantedBy=graphical-session.target, so enabling it is what makes it start --
# a plain `systemctl --user start` would not survive the next login.
say "Enabling the polkit agent"
systemctl --user enable --now hyprpolkitagent.service

# bluez ships disabled; the waybar bluetooth module stays empty without this.
if [ -d /sys/class/bluetooth ] && [ -n "$(ls -A /sys/class/bluetooth 2>/dev/null)" ]; then
  say "Bluetooth controller found, enabling bluetooth.service"
  sudo systemctl enable --now bluetooth.service
else
  echo "  no bluetooth controller; leaving bluetooth.service alone."
fi

say "Rendering Gruvbox Material colours"
"$repo/theme/render.sh"

if [ "$deploy" -eq 1 ]; then
  say "Deploying configs with stow"
  # --adopt would swallow existing files into the repo; refuse instead so the
  # user consciously moves anything already in ~/.config out of the way.
  stow --dir="$repo" --target="$HOME" --restow config
  echo "  symlinked $repo/config/.config -> ~/.config"
fi

say "Done."
echo "Log out and pick 'Hyprland' at your display manager."
