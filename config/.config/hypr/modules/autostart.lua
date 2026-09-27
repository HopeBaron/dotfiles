-- Long-running helpers, started once per login.
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- This block does NOT re-run on `hyprctl reload`, so nothing here is started
-- twice. The polkit agent is not here: install.sh enables it as a systemd
-- user service instead.

hl.on("hyprland.start", function()
    -- hyprpm's "enabled" plugins are not injected into a fresh Hyprland
    -- process on their own; reload them, then the config, so hy3 is active
    -- instead of silently falling back to the default layout.
    hl.exec_cmd("hyprpm reload -n && hyprctl reload")

    hl.exec_cmd("hyprpaper")      -- wallpaper
    hl.exec_cmd("waybar")         -- top bar
    hl.exec_cmd("swaync")         -- notifications + notification centre
    hl.exec_cmd("hypridle")       -- idle: dim -> lock -> suspend
    hl.exec_cmd("swayosd-server") -- volume/brightness popup (packages/utils.txt)

    -- Clipboard history; the picker is SUPER+SHIFT+V.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
