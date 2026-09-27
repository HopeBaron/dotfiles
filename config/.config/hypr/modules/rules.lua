-- Window and layer rules.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Apps asking to maximize themselves are ignored: tiling decides sizes.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

-- Hyprland's stock fix for dragging issues with XWayland popups.
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = "20 monitor_h-120",
    float = true,
})

-- Windows opened from waybar's status modules: floating, centred on the
-- cursor instead of squeezing the tiled layout.
hl.window_rule({
    name  = "float-settings",
    match = { class = "^(net-tui|pavucontrol|\\.blueman-manager-wrapped|blueman-manager)$" },
    float = true,
    size  = "900 600",
    move  = "cursor -450 -300",
})

-- rofi's default fade/scale-in reads as lag before a menu is usable; show
-- it instantly instead.
hl.layer_rule({
    name    = "no-anim-rofi",
    match   = { namespace = "^rofi$" },
    no_anim = true,
})
