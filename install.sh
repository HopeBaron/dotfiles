#!/usr/bin/env bash
# Bootstrap this Hyprland setup on a fresh Arch install.
#
#   ./install.sh            base + desktop packages, then deploy configs
#   ./install.sh --nvidia   the above, plus the NVIDIA driver stack
#   ./install.sh --no-deploy skip stow (packages only)
#
# Safe to re-run; every step is idempotent.
set -euo pipefail

repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
with_nvidia=0
deploy=1

for arg in "$@"; do
  case "$arg" in
    --nvidia)    with_nvidia=1 ;;
    --no-deploy) deploy=0 ;;
    -h|--help)   sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

say() { printf '\n\033[1;33m==>\033[0m %s\n' "$1"; }

# Strip comments and blanks from a manifest.
manifest() { sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$repo/packages/$1"; }

install_pkgs() {
  local file=$1 pkgs
  mapfile -t pkgs < <(manifest "$file")
  [ ${#pkgs[@]} -eq 0 ] && return 0
  say "Installing from packages/$file (${#pkgs[@]} packages)"
  sudo pacman -S --needed --noconfirm "${pkgs[@]}"
}

[ "$(id -u)" -eq 0 ] && { echo "Run as your normal user, not root." >&2; exit 1; }

say "Syncing package databases"
sudo pacman -Sy --noconfirm

install_pkgs base.txt

if [ "$with_nvidia" -eq 1 ]; then
  install_pkgs nvidia.txt
  # Bootloader-agnostic: set the DRM modeset flag via modprobe rather than
  # editing GRUB/systemd-boot entries. Hyprland will not start without it.
  say "Enabling nvidia_drm modeset"
  printf 'options nvidia_drm modeset=1 fbdev=1\n' \
    | sudo tee /etc/modprobe.d/nvidia-hyprland.conf >/dev/null
  # Regenerate the initramfs with whichever generator this system uses.
  if   command -v mkinitcpio >/dev/null; then sudo mkinitcpio -P
  elif command -v dracut-rebuild >/dev/null; then sudo dracut-rebuild
  else echo "  note: regenerate your initramfs manually before rebooting." >&2
  fi
fi

install_pkgs desktop.txt

say "Enabling services"
sudo systemctl enable --now NetworkManager.service
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service

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
[ "$with_nvidia" -eq 1 ] && echo "Reboot for the NVIDIA modeset change to take effect."
echo "Log out and pick 'Hyprland' at your display manager."
