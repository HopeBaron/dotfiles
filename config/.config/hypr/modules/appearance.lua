-- Gaps, borders, rounding, shadows, animations and hy3's tab bars.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/
local c = require("colors") -- rendered from the active theme (theme/render.sh)

-- "rrggbb" + alpha -> Hyprland colour strings.
local function rgba(hex, alpha) return "rgba(" .. hex .. (alpha or "ff") .. ")" end
local function argb(hex, alpha) return tonumber((alpha or "ff") .. hex, 16) end

hl.config({
    general = {
        layout = "hy3",

        gaps_in     = 2,
        gaps_out    = 4,
        border_size = 2,
        col = {
            active_border   = rgba(c.accent, "ee"),
            inactive_border = rgba(c.bg3, "aa"),
        },

        resize_on_border = false,
        allow_tearing    = false, -- see the wiki's Tearing page before enabling
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = argb(c.shadow, "ee"),
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    -- hy3's own tab bars (SUPER+W to group, [ ] to cycle, SUPER+SHIFT+W to
    -- lock) -- separate from Hyprland's native groupbar, which hy3 never uses.
    -- A locked group gets red rather than the accent so it stays visibly
    -- different from an ordinary active tab.
    plugin = {
        hy3 = {
            tabs = {
                colors = {
                    active          = rgba(c.accent, "ee"),
                    active_border   = rgba(c.accent, "ee"),
                    active_text     = rgba(c.accent_fg),

                    focused         = rgba(c.accent, "ee"),
                    focused_border  = rgba(c.accent, "ee"),
                    focused_text    = rgba(c.accent_fg),

                    inactive        = rgba(c.bg3, "aa"),
                    inactive_border = rgba(c.bg3, "aa"),
                    inactive_text   = rgba(c.fg1),

                    locked          = rgba(c.red, "ee"),
                    locked_border   = rgba(c.red, "ee"),
                    locked_text     = rgba(c.bg0),
                },
            },
        },
    },

    misc = {
        -- hyprpaper draws the wallpaper; this colour shows through wherever it
        -- doesn't (no image set, or while it starts). Both flags must be off
        -- or Hyprland's own mascot wallpaper covers it.
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        background_color        = argb(c.bg0),
    },

    animations = {
        enabled = true,
    },
})

-- Curves and animations: Hyprland's defaults.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

local animations = {
    -- leaf             speed  curve                      style
    { "global",         10,    { bezier = "default" } },
    { "border",         5.39,  { bezier = "easeOutQuint" } },
    { "windows",        4.79,  { spring = "easy" } },
    { "windowsIn",      4.1,   { spring = "easy" },         "popin 87%" },
    { "windowsOut",     1.49,  { bezier = "linear" },       "popin 87%" },
    { "fadeIn",         1.73,  { bezier = "almostLinear" } },
    { "fadeOut",        1.46,  { bezier = "almostLinear" } },
    { "fade",           3.03,  { bezier = "quick" } },
    { "layers",         3.81,  { bezier = "easeOutQuint" } },
    { "layersIn",       4,     { bezier = "easeOutQuint" }, "fade" },
    { "layersOut",      1.5,   { bezier = "linear" },       "fade" },
    { "fadeLayersIn",   1.79,  { bezier = "almostLinear" } },
    { "fadeLayersOut",  1.39,  { bezier = "almostLinear" } },
    { "workspaces",     1.94,  { bezier = "almostLinear" }, "fade" },
    { "workspacesIn",   1.21,  { bezier = "almostLinear" }, "fade" },
    { "workspacesOut",  1.94,  { bezier = "almostLinear" }, "fade" },
    { "zoomFactor",     7,     { bezier = "quick" } },
}

for _, a in ipairs(animations) do
    local leaf, speed, curve, style = a[1], a[2], a[3], a[4]
    hl.animation({
        leaf    = leaf,
        enabled = true,
        speed   = speed,
        bezier  = curve.bezier,
        spring  = curve.spring,
        style   = style,
    })
end
