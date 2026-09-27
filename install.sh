#!/usr/bin/env bash
# Deploy this Hyprland setup.
#
# Baseline is an EndeavourOS install: its installer already provides the base
# system, the NVIDIA driver and the audio/network services, so none of that
# is repeated here. Its display manager (GDM) is swapped for a themed SDDM.
#
#   ./install.sh              install packages, render colours, stow configs,
#                             install the SDDM login screen
#   ./install.sh --no-deploy  skip stow and SDDM (packages only)
#
# Safe to re-run; every step is idempotent.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
deploy=1

for arg in "$@"; do
  case "$arg" in
    --no-deploy) deploy=0 ;;
    -h|--help)   sed -n '2,12p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '\n\033[1;33m==>\033[0m %s\n' "$1"; }

# Strip comments and blanks from a manifest.
manifest() { sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$repo/packages/$1"; }

install_pkgs() {
  local file=$1 pkgs
  mapfile -t pkgs < <(manifest "$file")
  [ "${#pkgs[@]}" -eq 0 ] && return 0
  say "Installing from packages/$file (${#pkgs[@]} packages)"
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

# Copied, not stowed: the greeter runs as the sddm user, which cannot traverse
# a 0700 home, so symlinks into this repo would be dead ends for it.
install_sddm() {
  local src="$repo/system/sddm" theme=/usr/share/sddm/themes/gruvbox-material
  local wp ext dm state=/var/lib/sddm/state.conf
  say "Installing the SDDM login screen"
  sudo rm -rf "$theme"
  sudo install -Dm644 -t "$theme" "$src"/theme/*
  sudo install -Dm644 -t /etc/sddm.conf.d "$src"/sddm.conf.d/*

  # Same wallpaper as the desktop. Re-run ./install.sh after changing it.
  wp=$(sed -n 's/^[[:space:]]*path[[:space:]]*=[[:space:]]*//p' \
         "$repo/config/.config/hypr/hyprpaper.conf" | head -n1)
  wp=${wp/#\~/$HOME}
  if [ -f "$wp" ]; then
    ext=${wp##*.}
    sudo install -m644 "$wp" "$theme/background.$ext"
    sudo sed -i "s|^background=.*|background=background.$ext|" "$theme/theme.conf"
  else
    echo "  wallpaper '$wp' not found; the login screen falls back to plain bg0."
  fi

  # SDDM has no default-session option; it preselects the last session used,
  # which on first boot is whatever sorts first (GNOME). Seed it once.
  if ! sudo grep -qs '^Session=' "$state"; then
    printf '[Last]\nSession=/usr/share/wayland-sessions/hyprland-uwsm.desktop\nUser=%s\n' "$USER" \
      | sudo tee "$state" >/dev/null
    sudo chown sddm:sddm "$state"
  fi

  # Only one unit may own the display-manager.service alias, so the current
  # one (GDM on EndeavourOS) has to be disabled before sddm can be enabled.
  # Not --now: that would kill the running session. Takes effect next boot.
  dm=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null || true)
  if [ "$dm" != sddm.service ]; then
    [ -n "$dm" ] && [ "$dm" != display-manager.service ] && sudo systemctl disable "$dm"
    sudo systemctl enable sddm.service
    echo "  display manager: ${dm:-none} -> sddm (from next boot)"
  fi
}

[ "$(id -u)" -eq 0 ] && { echo "Run as your normal user, not root." >&2; exit 1; }

# Full upgrade, never a bare -Sy: refreshing the database without upgrading
# leaves you installing packages built against libraries you do not have.
say "Updating the system"
sudo pacman -Syu --noconfirm

# tools.txt first: it carries stow and gettext, which the deploy steps below
# call. EndeavourOS ships neither.
install_pkgs tools.txt
install_pkgs fonts.txt
install_pkgs desktop.txt

if command -v yay >/dev/null; then
  mapfile -t aur < <(manifest aur.txt)
  say "Installing from packages/aur.txt (${#aur[@]} packages)"
  yay -S --needed --noconfirm "${aur[@]}"
else
  echo "  yay not found; skipping packages/aur.txt (app icons fall back to breeze)."
fi

# GTK apps (swaync included) read the icon theme from this key, not from a
# file this repo could stow -- ~/.config/gtk-3.0 also holds user bookmarks.
gsettings set org.gnome.desktop.interface icon-theme 'Gruvbox-Plus-Dark'

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
  install_sddm
fi

say "Done."
echo "Reboot and log in with 'Hyprland (uwsm-managed)' at the SDDM screen."
