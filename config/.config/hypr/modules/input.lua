-- Keyboard, mouse and touchpad.
hl.config({
    input = {
        -- us,ara matches what localectl reports for X11.
        kb_layout  = "us,ara",
        kb_variant = ",",
        kb_model   = "",
        kb_rules   = "",
        -- SUPER+space cycles the layouts. An xkb option rather than a bind, so
        -- the switch happens inside xkb and Hyprland emits the activelayout
        -- event waybar's language module listens for.
        kb_options = "grp:win_space_toggle",

        follow_mouse = 1,
        sensitivity  = 0, -- -1.0 .. 1.0, 0 = unmodified

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- Three-finger horizontal swipe switches workspace.
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})
