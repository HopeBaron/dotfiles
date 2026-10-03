-- Key and mouse bindings. Every bind with a description shows up in the
-- SUPER+? cheat sheet automatically (scripts/rofi-help.sh reads them back).
-- See https://wiki.hypr.land/Configuring/Basics/Binds/
--
-- Key names are X11 keysyms: "grave" is `, "period" is ., "slash" is /,
-- "bracketleft"/"bracketright" are [ and ].
local programs = require("modules.programs")
local scripts  = programs.scripts
local hy3      = hl.plugin.hy3

local SUPER = "SUPER"

-- hl.bind with a cheat-sheet description. Copies `options`, so one options
-- table can be shared by several binds.
local function bind(keys, action, description, options)
    local merged = { description = description }
    for key, value in pairs(options or {}) do merged[key] = value end
    hl.bind(keys, action, merged)
end

local function run(command) return hl.dsp.exec_cmd(command) end

-- ---- apps and menus ---------------------------------------------------------

bind(SUPER .. " + Return",        run(programs.terminal),         "Terminal")
bind(SUPER .. " + E",             run(programs.file_manager),     "File manager (Dolphin)")
bind(SUPER .. " + SHIFT + E",     run(programs.tui_file_manager), "File manager (yazi)")
bind(SUPER .. " + R",             run(scripts.launcher),          "App launcher")
bind(SUPER .. " + Tab",           run(scripts.windows),           "Windows")
bind(SUPER .. " + SHIFT + V",     run(scripts.clipboard),         "Clipboard history")
bind(SUPER .. " + period",        run(scripts.utilities),         "Utilities: wallpaper, theme, accent")
bind(SUPER .. " + Escape",        run(scripts.power),             "Power menu")
bind(SUPER .. " + N",             run("swaync-client -t -sw"),    "Notification centre")
bind(SUPER .. " + SHIFT + slash", run(scripts.help),              "This cheat sheet")
bind("Print",                     run(scripts.screenshot),        "Screenshot menu")

-- ---- windows ----------------------------------------------------------------

bind(SUPER .. " + X",           hl.dsp.window.close(), "Close window")
bind(SUPER .. " + SHIFT + X",   hl.dsp.window.kill(),  "Force close window")
-- Maximize keeps the bar and gaps; fullscreen covers the whole output.
bind(SUPER .. " + F",           hl.dsp.window.fullscreen({ mode = "maximized" }),  "Maximize")
bind(SUPER .. " + SHIFT + F",   hl.dsp.window.fullscreen({ mode = "fullscreen" }), "Fullscreen")
bind(SUPER .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }),      "Toggle floating")
bind(SUPER .. " + P",           hl.dsp.window.pseudo(), "Pseudo-tile")

-- hy3 splits. There is no "toggle split" dispatcher; flipping the current
-- group to its opposite orientation is the same thing.
bind(SUPER .. " + T", hy3.change_group("opposite"), "Toggle split direction")
bind(SUPER .. " + V", hy3.change_group("v"),        "Split vertical")
bind(SUPER .. " + C", hy3.change_group("h"),        "Split horizontal")

-- hy3 tab groups (not Hyprland's native groups, which hy3's tree ignores).
bind(SUPER .. " + W",            hy3.make_group("tab", { toggle = true }), "Tab-group/ungroup window")
bind(SUPER .. " + SHIFT + W",    hy3.lock_tab(),                           "Lock tab group")
bind(SUPER .. " + bracketleft",  hy3.focus_tab({ direction = "l" }),       "Previous tab")
bind(SUPER .. " + bracketright", hy3.focus_tab({ direction = "r" }),       "Next tab")

-- Focus and move, with arrows or vim-style hjkl -- both do the same thing.
-- `once` moves a window one step, instead of hy3's default of re-parenting
-- it repeatedly until it can't move any further.
local directions = {
    -- arrow   vim  hy3  name
    { "left",  "H", "l", "left"  },
    { "right", "L", "r", "right" },
    { "up",    "K", "u", "up"    },
    { "down",  "J", "d", "down"  },
}
for _, d in ipairs(directions) do
    local arrow, vim_key, dir, name = d[1], d[2], d[3], d[4]
    for _, key in ipairs({ arrow, vim_key }) do
        bind(SUPER .. " + " .. key,             hy3.move_focus(dir),                  "Focus " .. name)
        bind(SUPER .. " + SHIFT + " .. key,     hy3.move_window(dir, { once = true }), "Move window " .. name)
    end
end

-- Focus the parent group / back into the child (i3's "focus parent").
bind(SUPER .. " + A",         hy3.change_focus("raise"), "Focus parent (raise)")
bind(SUPER .. " + SHIFT + A", hy3.change_focus("lower"), "Focus child (lower)")

-- Mouse: SUPER + left-drag moves, SUPER + right-drag resizes.
hl.bind(SUPER .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(SUPER .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ---- workspaces -------------------------------------------------------------
-- Left without descriptions on purpose: the cheat sheet shows one summary
-- line for these instead of twenty.

for i = 1, 10 do
    local key = i % 10 -- workspace 10 is on the 0 key
    hl.bind(SUPER .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(SUPER .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(SUPER .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(SUPER .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

bind(SUPER .. " + Q",         hl.dsp.workspace.toggle_special("magic"),          "Scratchpad")
bind(SUPER .. " + SHIFT + Q", hl.dsp.window.move({ workspace = "special:magic" }), "Move to scratchpad")

-- ---- media keys -------------------------------------------------------------
-- swayosd-client both makes the change and shows the on-screen popup.
-- swayosd is in packages/utils.txt (./install.sh --utils); without it these
-- keys do nothing.

local function osd(args) return run("swayosd-client " .. args) end
local media   = { locked = true, repeating = true } -- work on the lock screen, repeat when held
local player  = { locked = true }

bind("XF86AudioRaiseVolume",  osd("--output-volume raise --max-volume 100"), "Volume up",       media)
bind("XF86AudioLowerVolume",  osd("--output-volume lower"),                  "Volume down",     media)
bind("XF86AudioMute",         osd("--output-volume mute-toggle"),            "Mute output",     media)
bind("XF86AudioMicMute",      osd("--input-volume mute-toggle"),             "Mute microphone", media)
bind("XF86MonBrightnessUp",   osd("--brightness raise"),                     "Brightness up",   media)
bind("XF86MonBrightnessDown", osd("--brightness lower"),                     "Brightness down", media)

bind("XF86AudioNext",  osd("--playerctl next"),       "Next track",     player)
bind("XF86AudioPause", osd("--playerctl play-pause"), "Play / pause",   player)
bind("XF86AudioPlay",  osd("--playerctl play-pause"), "Play / pause",   player)
bind("XF86AudioPrev",  osd("--playerctl prev"),       "Previous track", player)
