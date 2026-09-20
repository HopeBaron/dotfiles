# dotfiles

Hyprland desktop, themed Gruvbox Material. Targets a bare Arch install — every
binary referenced by any config is listed in `packages/`.

## Install

```sh
git clone <this repo> ~/dotfiles
cd ~/dotfiles
./install.sh --nvidia     # drop --nvidia on AMD/Intel
```

Then reboot (if `--nvidia`) and pick **Hyprland** at the display manager.

## Layout

```
install.sh              bootstrap: packages -> services -> render -> stow
packages/base.txt       what a fresh archinstall lacks (audio, network, fonts, ...)
packages/nvidia.txt     driver stack, only with --nvidia
packages/desktop.txt    Hyprland and its components
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
