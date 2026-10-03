# dotfiles

A Hyprland desktop on EndeavourOS, themed end to end from one palette:
Gruvbox Material in all its variants, or the house theme **GruvMoon**. Every
binary any config calls is listed in `packages/`.

## Install

```sh
git clone <this repo> ~/personal/projects/mars/dotfiles
cd ~/personal/projects/mars/dotfiles
./install.sh            # add --utils for the extras in packages/utils.txt
```

Then reboot and pick **Hyprland (uwsm-managed)** at the SDDM login screen.

EndeavourOS's installer already provides the base system, the NVIDIA driver
and the audio/network services, so `install.sh` doesn't repeat them. It does
replace GDM with SDDM running a theme that mirrors the lock screen. Every step
is idempotent; re-run it after pulling changes.

## Layout

```
install.sh                packages -> theme -> stow -> commands -> SDDM
bin/                      commands, linked into ~/.local/bin by install.sh
  mars-theme              switch theme / accent and apply it everywhere
  mars-wallpaper          switch wallpaper
lib/mars.sh               paths + helpers shared by bin/ and the menu scripts
packages/                 package lists (see the header of each)
theme/
  lib.sh                  theme ids, loading, accent, derived values, saved state
  gruvbox-material.sh     the upstream palette table (all variants)
  themes/gruvmoon.sh      the house theme: a plain, hand-editable palette
  templates/              one template per themed app, ${VAR} placeholders
  render.sh               templates -> app configs (the RENDER_TABLE)
config/                   stow package, mirrors ~ (.config, .local/share)
  .config/hypr/
    hyprland.lua          entry point; the config itself is in modules/
    modules/              monitors, environment, autostart, appearance,
                          input, keybinds, rules, programs
    scripts/              the rofi menus (lib is ../../../../lib/mars.sh)
system/sddm/              login screen; copied (not stowed) into /usr/share + /etc
wallpapers/               your images (gitignored; the picker lists them)
```

## Theming

Pick with **SUPER+.** (Wallpaper / Theme / Accent colour), or from a shell:

```sh
mars-theme list                        # GruvMoon + 18 Gruvbox Material variants
mars-theme set gruvbox-material-light-soft-material
mars-theme accent aqua                 # red orange yellow green aqua blue purple
mars-theme accent '#d65d0e'            # or any hex
mars-wallpaper set wallhaven-3qkggv.jpg
```

A theme is *mode* (dark/light) × *background* (hard/medium/soft) ×
*foreground* (material/mix/original), exactly the options of the Vim plugin.
A named accent follows the theme (a darker green on light themes); a custom
hex stays fixed. Text drawn on the accent picks dark or light by the accent's
brightness, so any colour stays readable.

The choice is saved in `~/.local/state/mars/` and applied live to Hyprland,
waybar, swaync, swayosd, kitty, rofi, GTK3 apps and running Neovim. Qt/KDE
and GTK4 apps pick it up on their next start. The SDDM login screen
is system-wide: re-run `./install.sh` to update it.

### Adding or changing colours

- **Never write a hex value into an app config.** Add a template to
  `theme/templates/`, add it to `RENDER_TABLE` in `theme/render.sh` and to
  `.gitignore` (rendered files are build output), then `mars-theme apply`.
- Use `${ACCENT}` for "the highlight colour" and `${ACCENT_FG}` for text on
  it; use `${GREEN}`/`${RED}`... only where the hue itself means something
  (success, terminal ANSI colours).
- A new theme: copy `theme/themes/gruvmoon.sh` to `theme/themes/<id>.sh`
  and edit the values. It appears in the picker automatically.

## Keybinds

**SUPER+?** shows all of them, read live from the config. The ones to know:

| Keys | Action |
|---|---|
| SUPER+Return | terminal (kitty) |
| SUPER+R / SUPER+Tab | app launcher / window switcher |
| SUPER+E / SUPER+SHIFT+E | Nautilus / yazi |
| SUPER+SHIFT+V | clipboard history (image preview, pins) |
| SUPER+. | wallpaper, theme, accent |
| SUPER+Escape | power menu |
| SUPER+` / SUPER+SHIFT+` | lock / keep-awake |
| SUPER+N | notification centre |
| Print | screenshot / screen-recording menu |
| SUPER+1…0 | workspaces |
