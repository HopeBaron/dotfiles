#!/usr/bin/env bash
# Install Caelestia from THIS checkout, so the shell, CLI and Hyprland config
# can be edited in place and tracked in git (the AUR packages install read-only
# copies under /usr that we could not change).
#
#   ./local-install.sh            everything below, in order
#   ./local-install.sh packages   system + AUR packages (asks for sudo)
#   ./local-install.sh shell      build shell/, install its plugin, link the QML
#   ./local-install.sh cli        install cli/ into a private venv, link `caelestia`
#   ./local-install.sh dots       link hypr/ into ~/.config (the old one is kept aside)
#   ./local-install.sh qt         optional: Qt/GTK theming packages (qtengine, Darkly, Papirus)
#   ./local-install.sh firefox    colour Firefox from the scheme (close Firefox first; restart it after a scheme change)
#   ./local-install.sh sddm       optional: the Caelestia login screen (asks for sudo; re-run after a scheme change)
#   ./local-install.sh check      verify everything above is in place; changes nothing
#
# Every step is safe to re-run. Nothing here is Caelestia-version-specific:
# update by editing/pulling the folders and re-running the step you changed.
set -euo pipefail

readonly REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
readonly CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
readonly DATA=${XDG_DATA_HOME:-$HOME/.local/share}/caelestia
readonly SHELL_VERSION=2.5.0   # the release shell/ was copied after; shown in the shell, not used for anything else

say()  { printf '\n\033[1;35m==>\033[0m %s\n' "$1"; }
note() { printf '    %s\n' "$1"; }

# ---- packages ---------------------------------------------------------------

# From the manual-install list in shell/README.md, plus what hypr/ starts
# (hypr/hyprland/execs.lua) and the build tools.
readonly REPO_PACKAGES=(
  hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  cmake ninja qt6-base qt6-declarative qt6-imageformats qt6-multimedia qt6-shadertools
  ddcutil brightnessctl networkmanager lm_sensors aubio pipewire libqalculate
  power-profiles-daemon swappy fish fuzzel dart-sass
  ttf-material-symbols-variable ttf-cascadia-code-nerd ttf-jetbrains-mono-nerd
  gnome-keyring polkit-gnome cliphist wl-clipboard trash-cli gammastep geoclue
  python python-pillow python-pip
)
# quickshell-git REPLACES the repo's quickshell: the shell needs the git version.
readonly AUR_PACKAGES=(quickshell-git qt6-m3shapes-git libcava ttf-rubik-vf python-materialyoucolor)

step_packages() {
  say "Packages"
  sudo pacman -S --needed "${REPO_PACKAGES[@]}"
  note "AUR: ${AUR_PACKAGES[*]} (quickshell-git replaces quickshell -- say yes)"
  yay -S --needed "${AUR_PACKAGES[@]}"
}

# ---- shell ------------------------------------------------------------------

step_shell() {
  say "Shell: build and install the plugin"
  # The QML itself is NOT copied anywhere: ~/.config/quickshell/caelestia is a
  # link to shell/, so editing a file here changes the running shell. Only the
  # C++ plugin and the version helper are installed system-wide. The config
  # files cmake also wants to install go to a scratch directory and are dropped.
  local scratch
  scratch=$(mktemp -d)
  # `cmake --install` runs as root, so what it wrote there belongs to root.
  trap 'sudo rm -rf "$scratch"' RETURN
  # shell/ has no git metadata here, and its CMakeLists takes VERSION and
  # GIT_REVISION from `git describe` / `git rev-parse` unless they are given:
  # the version of the release it tracks, and the upstream commit recorded in
  # UPSTREAM.md.
  local revision
  revision=$(awk -F'|' '/shell\//{gsub(/ /,"",$4); print $4}' "$REPO/UPSTREAM.md")
  ( cd "$REPO/shell"
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ \
      -DVERSION="$SHELL_VERSION" -DGIT_REVISION="${revision:-unknown}" \
      -DINSTALL_QSCONFDIR="$scratch/qs"
    cmake --build build
    sudo cmake --install build )

  say "Shell: link the QML"
  mkdir -p "$CONFIG/quickshell"
  local target=$CONFIG/quickshell/caelestia
  if [[ -e "$target" && ! -L "$target" ]]; then
    mv "$target" "$target.bak.$(date +%s)"
    note "kept the existing $target aside"
  fi
  ln -sfn "$REPO/shell" "$target"
  note "$target -> $REPO/shell"
}

# ---- cli --------------------------------------------------------------------

step_cli() {
  say "CLI"
  # A venv that can see the system packages (python-materialyoucolor and
  # python-pillow come from pacman). hatch-vcs wants git metadata, which this
  # copy of the CLI does not have, so the version is given explicitly.
  python -m venv --system-site-packages "$DATA/venv"
  local version
  version=$(sed -n 's/^## *\([0-9][0-9.]*\).*/\1/p' "$REPO/cli/README.md" | head -n1)
  SETUPTOOLS_SCM_PRETEND_VERSION=${version:-1.1.3} \
    "$DATA/venv/bin/pip" install --quiet --upgrade "$REPO/cli"
  mkdir -p "$HOME/.local/bin"
  ln -sfn "$DATA/venv/bin/caelestia" "$HOME/.local/bin/caelestia"
  note "caelestia -> $DATA/venv/bin/caelestia"
}

# ---- dots -------------------------------------------------------------------

step_dots() {
  say "Hyprland config"
  local target=$CONFIG/hypr
  if [[ -e "$target" && ! -L "$target" ]]; then
    mv "$target" "$target.bak.$(date +%s)"
    note "kept the existing $target aside"
  fi
  ln -sfn "$REPO/hypr" "$target"
  note "$target -> $REPO/hypr"

  # hypr/hyprland.lua loads ~/.config/caelestia/hypr-vars.lua and hypr-user.lua
  # (your overrides) and cannot create them if the folder is missing -- it then
  # trips Hyprland's emergency mode, with no binds at all.
  mkdir -p "$CONFIG/caelestia"
  [[ -e "$CONFIG/caelestia/hypr-vars.lua" ]] || printf 'return {}\n' > "$CONFIG/caelestia/hypr-vars.lua"
  [[ -e "$CONFIG/caelestia/hypr-user.lua" ]] || : > "$CONFIG/caelestia/hypr-user.lua"
  note "$CONFIG/caelestia/ (hypr-vars.lua, hypr-user.lua): your overrides, never touched by updates"

  # The bar stays hidden until you hover the left edge or something happens
  # (BarWrapper.qml reveals it briefly on workspace switches, urgent windows
  # and notifications), and the menus open over fullscreen windows. Only
  # written if you have no shell.json yet.
  [[ -e "$CONFIG/caelestia/shell.json" ]] \
    || printf '{\n    "general": {\n        "showOverFullscreen": true\n    },\n    "bar": {\n        "persistent": false,\n        "showOnHover": true\n    },\n    "lock": {\n        "hideNotifs": true\n    }\n}\n' > "$CONFIG/caelestia/shell.json"

  # What the manifest's post_install does for the shell.
  local state=${XDG_STATE_HOME:-$HOME/.local/state}/caelestia
  if [[ ! -f "$state/scheme.json" ]] && command -v caelestia >/dev/null; then
    caelestia scheme set -n caelestia || true
  fi
}

# ---- qt / gtk theming (optional) -------------------------------------------

# The manifest's "qt" and "gtk" components. hypr/ sets QT_QPA_PLATFORMTHEME to
# qtengine, so Qt apps only follow the scheme once these are installed.
step_qt() {
  say "Qt and GTK theming"
  sudo pacman -S --needed adw-gtk-theme papirus-icon-theme
  yay -S --needed qtengine frameworkintegration darkly-bin papirus-folders
}

# ---- firefox (optional) -----------------------------------------------------

# Firefox's own UI and pages in the scheme's colours, with no extension: a
# template (firefox/colours/caelestia-colours.css) is rendered by `caelestia`
# on every scheme change, and each profile's userChrome.css / userContent.css
# import the result. Firefox only reads stylesheets at startup, so restart it
# after changing the scheme.
step_firefox() {
  say "Firefox colours"
  local src=$REPO/firefox/colours theme=${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/theme

  mkdir -p "$CONFIG/caelestia/templates"
  ln -sfn "$src/caelestia-colours.css" "$CONFIG/caelestia/templates/firefox-colours.css"
  note "template: $CONFIG/caelestia/templates/firefox-colours.css"

  # Render it now, with the scheme already in use.
  if command -v caelestia >/dev/null; then
    local name flavour variant
    { read -r name; read -r flavour; read -r variant; } < <(caelestia scheme get -nfv)
    caelestia scheme set -n "$name" -f "$flavour" -v "$variant" || true
  fi

  local root profile found=0
  for root in "$HOME/.config/mozilla/firefox" "$HOME/.mozilla/firefox"; do
    for profile in "$root"/*.default*; do
      [[ -d "$profile" ]] || continue
      found=1
      mkdir -p "$profile/chrome"
      local file
      for file in chrome/userChrome.css:userChrome.css chrome/userContent.css:userContent.css user.js:user.js; do
        local dest=$profile/${file%%:*} from=$src/${file##*:}
        # Leftovers from the old setup are dropped; anything else is kept aside.
        if [[ -e "$dest" && ! -L "$dest" ]]; then
          if grep -qi mars "$dest"; then rm -f "$dest"; else mv "$dest" "$dest.bak.$(date +%s)"; fi
        fi
        ln -sfn "$from" "$dest"
      done
      ln -sfn "$theme/firefox-colours.css" "$profile/chrome/caelestia-colours.css"
      note "$profile"
    done
  done
  (( found )) || note "no Firefox profile found (start Firefox once, then run this again)"
}

# ---- login screen (optional) -----------------------------------------------

step_sddm() {
  say "SDDM login theme"
  "$REPO/sddm/install.sh"
}

# ---- check ------------------------------------------------------------------

step_check() {
  local bad=0
  ok()   { printf '  [32mok[0m   %s
' "$1"; }
  fail() { printf '  [31mMISSING[0m %s
' "$1"; bad=$((bad + 1)); }
  have() { if "$@" >/dev/null 2>&1; then return 0; else return 1; fi; }

  say "Packages"
  local p
  for p in "${REPO_PACKAGES[@]}" "${AUR_PACKAGES[@]}"; do
    have pacman -Qq "$p" && ok "$p" || fail "package $p"
  done

  say "Shell"
  [[ -f /usr/lib/qt6/qml/Caelestia/qmldir ]] && ok "QML plugin installed" || fail "QML plugin (run: ./local-install.sh shell)"
  [[ -f /usr/lib/caelestia/version ]]       && ok "version helper"       || fail "/usr/lib/caelestia/version"
  [[ "$(readlink "$CONFIG/quickshell/caelestia" 2>/dev/null)" == "$REPO/shell" ]] \
    && ok "$CONFIG/quickshell/caelestia -> shell/" || fail "QML link (run: ./local-install.sh shell)"

  say "CLI"
  have caelestia --help && ok "caelestia runs" || fail "caelestia command (run: ./local-install.sh cli)"

  say "Hyprland"
  [[ -f "$CONFIG/caelestia/hypr-vars.lua" ]] && ok "$CONFIG/caelestia/hypr-vars.lua" || fail "overrides folder (run: ./local-install.sh dots)"
  [[ "$(readlink "$CONFIG/hypr" 2>/dev/null)" == "$REPO/hypr" ]] \
    && ok "$CONFIG/hypr -> hypr/" || fail "hypr link (run: ./local-install.sh dots)"
  [[ -f "${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/scheme.json" ]] \
    && ok "colour scheme set" || fail "scheme (run: caelestia scheme set -n caelestia)"

  say "Running"
  pgrep -f "qs -c caelestia|quickshell -c caelestia|-c caelestia" >/dev/null \
    && ok "caelestia shell is running" || note "not running -- start it: caelestia shell -d"

  echo
  (( bad == 0 )) && echo "All set." || { echo "$bad item(s) missing."; return 1; }
}

main() {
  if (( $(id -u) == 0 )); then echo "run as your own user (sudo is used where needed)" >&2; exit 1; fi
  case "${1:-all}" in
    packages) step_packages ;;
    shell)    step_shell ;;
    cli)      step_cli ;;
    dots)     step_dots ;;
    qt)       step_qt ;;
    firefox)  step_firefox ;;
    sddm)     step_sddm ;;
    check)    step_check ;;
    all)      step_packages; step_cli; step_shell; step_dots
              say "Done. Log out and back in (or run: caelestia shell -d)." ;;
    *) sed -n '2,/^[^#]/{/^#/p}' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
  esac
}

main "$@"
