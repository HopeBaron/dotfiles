-- Environment for every app Hyprland starts.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Qt has no theming of its own outside a desktop environment; without this it
-- falls back to a stock style that ignores the theme. qt6ct's scheme is
-- rendered from the active theme like everything else (theme/render.sh).
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-- GTK 4.22 ignores gtk-theme-name for plain (non-libadwaita) GTK4 apps such as
-- pavucontrol; only this variable makes them load the rendered theme.
hl.env("GTK_THEME", "Gruvbox-Material")

-- NVIDIA (proprietary driver) + wlroots hardware-cursor planes don't reliably
-- release/reacquire across a VT switch: switching TTY away from an active
-- hyprlock froze the compositor. Software cursors are Hyprland's documented
-- NVIDIA workaround and remove that failure mode.
hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})
