#!/usr/bin/env bash
# Deploy this Hyprland setup.
#
# Baseline is an EndeavourOS install: its installer already provides the base
# packages, the NVIDIA driver, the display manager and the audio/network
# services, so none of that is repeated here.
#
#   ./install.sh              desktop packages, render colours, stow configs
#   ./install.sh --bare-arch  also install base packages + enable services
#   ./install.sh --nvidia     also install the NVIDIA stack and set DRM modeset
#   ./install.sh --no-deploy  skip stow (packages only)
#
# Safe to re-run; every step is idempotent.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
bare_arch=0
with_nvidia=0
deploy=1

for arg in "$@"; do
  case "$arg" in
    --bare-arch) bare_arch=1 ;;
    --nvidia)    with_nvidia=1 ;;
    --no-deploy) deploy=0 ;;
    -h|--help)   sed -n '2,13p' "$0"; exit 0 ;;
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

if [ "$bare_arch" -eq 1 ]; then
  install_pkgs base.txt
  say "Enabling base services"
  sudo systemctl enable --now NetworkManager.service
  systemctl --user enable --now wireplumber.service
  echo "  note: pipewire is socket-activated and needs no enabling."
  echo "  note: install a display manager yourself, or start Hyprland from a TTY."
fi

if [ "$with_nvidia" -eq 1 ]; then
  install_pkgs nvidia.txt
  # Bootloader-agnostic: set the DRM modeset flag via modprobe rather than
  # editing GRUB/systemd-boot entries. Hyprland will not start without it.
  say "Enabling nvidia_drm modeset"
  printf 'options nvidia_drm modeset=1 fbdev=1\n' \
    | sudo tee /etc/modprobe.d/nvidia-hyprland.conf >/dev/null
  # Regenerate the initramfs with whichever generator this system uses.
  if   command -v dracut-rebuild >/dev/null; then sudo dracut-rebuild
  elif command -v mkinitcpio >/dev/null; then sudo mkinitcpio -P
  else echo "  note: regenerate your initramfs manually before rebooting." >&2
  fi
fi

install_pkgs desktop.txt

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
if [ "$with_nvidia" -eq 1 ]; then
  echo "Reboot for the NVIDIA modeset change to take effect."
fi
echo "Log out and pick 'Hyprland' at your display manager."
