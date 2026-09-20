# dotfiles

Hyprland desktop, themed Gruvbox Material. Every binary referenced by any
config is listed in `packages/`.

Baseline is an **EndeavourOS** install — its installer already provides the base
packages, the NVIDIA driver, the display manager and the audio/network services,
so `install.sh` does not repeat any of that.

## Install

```sh
git clone <this repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

Then log out and pick **Hyprland** at the display manager.

On plain Arch rather than EndeavourOS:

```sh
./install.sh --bare-arch --nvidia   # drop --nvidia on AMD/Intel
```

`--bare-arch` adds the base packages and enables NetworkManager/wireplumber; it
does *not* install a display manager, so either add one or start Hyprland from a
TTY. `--nvidia` installs the driver stack, sets `nvidia_drm.modeset=1` via
modprobe, and regenerates the initramfs — reboot afterwards.

## Layout

```
install.sh              packages -> render -> stow
packages/desktop.txt    Hyprland and its components (the default path)
packages/base.txt       plain-Arch extras, only with --bare-arch
packages/nvidia.txt     driver stack, only with --nvidia
theme/palette.sh        SINGLE SOURCE OF TRUTH for colour
theme/templates/        per-app colour templates, ${VAR} placeholders
theme/render.sh         templates + palette -> generated colour files
config/                 stow package, mirrors ~/.config
```

## Theming

Never write a hex value into an app config. Add a template to
`theme/templates/`, wire it into `render()` in `theme/render.sh`, then:

```sh
./theme/render.sh && hyprctl reload
```

Palette is Gruvbox Material `background=medium`, `foreground=material`,
transcribed from [sainnhe/gruvbox-material](https://github.com/sainnhe/gruvbox-material)
(`autoload/gruvbox_material.vim`). The two options are independent: `background`
sets `bg*` only, `foreground` sets accents only.

## Keybinds

`SUPER+Q` terminal · `SUPER+C` close · `SUPER+V` float · `SUPER+1-9` workspace
· `SUPER+arrows` focus · `SUPER+drag` move/resize · `SUPER+M` exit

## Not yet installed

These binds are commented out in `hyprland.lua` until the package exists:

- `SUPER+R` launcher
- `SUPER+E` file manager

Still to add: bar, notification daemon, lockscreen, wallpaper, polkit agent,
clipboard manager, screenshot tool.
