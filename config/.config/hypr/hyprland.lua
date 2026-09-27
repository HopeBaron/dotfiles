-- Hyprland config entry point. Each concern lives in its own module under
-- modules/; this file only decides the order they load in.
--
--   modules/monitors.lua     displays
--   modules/environment.lua  env vars for every app (Qt/GTK theming, cursor)
--   modules/autostart.lua    bar, notifications, idle, clipboard, ... (once per login)
--   modules/appearance.lua   gaps, borders, animations, hy3 tabs -- uses colors.lua
--   modules/input.lua        keyboard layouts, mouse, touchpad
--   modules/keybinds.lua     every binding (SUPER+? lists them)
--   modules/rules.lua        window and layer rules
--   modules/programs.lua     which terminal/file manager/scripts the binds launch
--
-- colors.lua is rendered from the active theme by theme/render.sh; switch
-- themes with SUPER+. or `mars-theme`, never by editing it.

-- Lua caches required modules for the life of the process. Drop ours so a
-- `hyprctl reload` (which every theme switch does) reads them afresh.
for name in pairs(package.loaded) do
    if name == "colors" or name:match("^modules%.") then
        package.loaded[name] = nil
    end
end

require("modules.monitors")
require("modules.environment")
require("modules.autostart")
require("modules.appearance")
require("modules.input")
require("modules.keybinds")
require("modules.rules")
