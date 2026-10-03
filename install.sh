#!/usr/bin/env bash
# Deploy this Hyprland setup.
#
# Baseline is an EndeavourOS install: its installer already provides the base
# system, the NVIDIA driver and the audio/network services, so none of that
# is repeated here. Its display manager (GDM) is swapped for a themed SDDM.
#
#   ./install.sh              packages, theme, configs (stow), commands, SDDM
#   ./install.sh --no-deploy  packages only: skip theme, stow, commands, SDDM
#   ./install.sh --config-only  theme, stow, commands, SDDM only: skip the
#                              system upgrade and package installs entirely
#                              (for re-applying config changes, e.g. after
#                              editing something under config/ or system/)
#   ./install.sh --utils      also install packages/utils.txt
#
# Safe to re-run; every step is idempotent.
set -euo pipefail

readonly REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly SDDM_THEME_DIR=/usr/share/sddm/themes/gruvbox-material
readonly SDDM_STATE=/var/lib/sddm/state.conf
readonly DEFAULT_SESSION=/usr/share/wayland-sessions/hyprland-uwsm.desktop

DEPLOY=1
WITH_UTILS=0
CONFIG_ONLY=0

# ---- helpers -----------------------------------------------------------------

say()  { printf '\n\033[1;33m==>\033[0m %s\n' "$1"; }
note() { printf '  %s\n' "$1"; }

usage() {
  sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

# A package list without its comments and blank lines.
manifest() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$REPO/packages/$1"
}

install_packages() {
  local list=$1 packages
  mapfile -t packages < <(manifest "$list")
  (( ${#packages[@]} )) || return 0
  say "Installing packages/$list (${#packages[@]} packages)"
  sudo pacman -S --needed --noconfirm "${packages[@]}"
}

# ---- steps -------------------------------------------------------------------

parse_args() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      --no-deploy)   DEPLOY=0 ;;
      --config-only) CONFIG_ONLY=1 ;;
      --utils)       WITH_UTILS=1 ;;
      -h|--help)     usage ;;
      *) echo "unknown option: $arg" >&2; usage 2 ;;
    esac
  done
}

check_not_root() {
  if (( $(id -u) == 0 )); then
    echo "Run as your normal user, not root (sudo is used where needed)." >&2
    exit 1
  fi
}

update_system() {
  # A full upgrade, never a bare -Sy: refreshing the database without
  # upgrading leaves you installing packages built against libraries you
  # don't have yet.
  say "Updating the system"
  sudo pacman -Syu --noconfirm
}

install_all_packages() {
  # tools.txt first: it carries stow and gettext (envsubst), which the later
  # steps call and EndeavourOS doesn't ship.
  install_packages tools.txt
  install_packages fonts.txt
  install_packages desktop.txt
  (( WITH_UTILS )) && install_packages utils.txt

  if command -v yay >/dev/null; then
    local aur
    mapfile -t aur < <(manifest aur.txt)
    say "Installing packages/aur.txt (${#aur[@]} packages)"
    yay -S --needed --noconfirm "${aur[@]}"
  else
    note "yay not found; skipping packages/aur.txt (app icons fall back to Adwaita)."
  fi
}

enable_services() {
  # WantedBy=graphical-session.target: enabling is what makes it start at
  # every login; a plain `start` would not survive a reboot.
  say "Enabling the polkit agent"
  systemctl --user enable --now hyprpolkitagent.service

  # bluez ships disabled; waybar's bluetooth module stays empty without it.
  if [[ -n "$(ls -A /sys/class/bluetooth 2>/dev/null)" ]]; then
    say "Bluetooth controller found, enabling bluetooth.service"
    sudo systemctl enable --now bluetooth.service
  else
    note "no bluetooth controller; leaving bluetooth.service alone."
  fi
}

# Renders every themed config for the saved (or default) theme and pushes it
# to GTK/Qt/running apps. Must run before stow: the rendered files are what
# gets linked.
apply_theme() {
  say "Rendering the theme"
  "$REPO/bin/mars-theme" apply
  "$REPO/bin/mars-theme" current | sed 's/^/  /'
}

deploy_configs() {
  # --restow without --adopt: stow refuses to overwrite real files already in
  # ~/.config, so moving them aside is a conscious step, never data loss.
  say "Linking configs into ~ with stow"
  stow --dir="$REPO" --target="$HOME" --restow config
  note "$REPO/config -> ~"
}

link_commands() {
  say "Linking commands into ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  local cmd
  for cmd in "$REPO"/bin/*; do
    ln -sfn "$cmd" "$HOME/.local/bin/$(basename "$cmd")"
    note "$(basename "$cmd")"
  done
  # Links to commands that were since renamed or removed from bin/.
  find "$HOME/.local/bin" -maxdepth 1 -xtype l -lname "$REPO/bin/*" -delete
}

# Copied, not stowed: the greeter runs as the sddm user, which cannot traverse
# a 0700 home, so symlinks into this repo would be dead ends for it.
install_sddm() {
  say "Installing the SDDM login screen"
  sudo rm -rf "$SDDM_THEME_DIR"
  sudo install -Dm644 -t "$SDDM_THEME_DIR" "$REPO"/system/sddm/theme/*
  sudo install -Dm644 -t /etc/sddm.conf.d "$REPO"/system/sddm/sddm.conf.d/*

  # Same wallpaper as the desktop. Re-run ./install.sh after changing it.
  local wallpaper
  wallpaper=$("$REPO/bin/mars-wallpaper" current)
  if [[ -f "$wallpaper" ]]; then
    local ext=${wallpaper##*.}
    sudo install -m644 "$wallpaper" "$SDDM_THEME_DIR/background.$ext"
    sudo sed -i "s|^background=.*|background=background.$ext|" "$SDDM_THEME_DIR/theme.conf"
  else
    note "no wallpaper set yet; the login screen uses the theme's plain background."
  fi

  # SDDM has no default-session option; it preselects the last session used,
  # which on a first boot is whatever sorts first (GNOME). Seed it once.
  if ! sudo grep -qs '^Session=' "$SDDM_STATE"; then
    printf '[Last]\nSession=%s\nUser=%s\n' "$DEFAULT_SESSION" "$USER" | sudo tee "$SDDM_STATE" >/dev/null
    sudo chown sddm:sddm "$SDDM_STATE"
  fi

  switch_display_manager_to_sddm
}

switch_display_manager_to_sddm() {
  # Only one unit may own the display-manager.service alias, so the current
  # one (GDM on EndeavourOS) is disabled first. Not --now: that would end the
  # running session. Takes effect at the next boot.
  local current
  current=$(basename "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" 2>/dev/null || true)
  [[ "$current" == sddm.service ]] && return 0
  if [[ -n "$current" && "$current" != display-manager.service ]]; then
    sudo systemctl disable "$current"
  fi
  sudo systemctl enable sddm.service
  note "display manager: ${current:-none} -> sddm (from next boot)"
}

deploy_all() {
  apply_theme
  deploy_configs
  link_commands
  install_sddm
}

main() {
  parse_args "$@"
  check_not_root
  if (( CONFIG_ONLY )); then
    deploy_all
    say "Done."
    echo "Reboot and log in with 'Hyprland (uwsm-managed)' at the SDDM screen."
    return
  fi
  update_system
  install_all_packages
  enable_services
  (( DEPLOY )) && deploy_all
  say "Done."
  echo "Reboot and log in with 'Hyprland (uwsm-managed)' at the SDDM screen."
}

main "$@"
