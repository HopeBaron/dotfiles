-- Programs and scripts the rest of the config launches. Change an app here
-- and every bind/autostart that uses it follows.
local scripts = os.getenv("HOME") .. "/.config/hypr/scripts"

return {
    terminal       = "kitty",
    file_manager   = "dolphin",
    tui_file_manager = "kitty -e yazi", -- TUI, needs a terminal

    scripts = {
        launcher   = scripts .. "/rofi-launch.sh",
        windows    = scripts .. "/rofi-windows.sh",
        clipboard  = scripts .. "/rofi-clipboard.sh",
        screenshot = scripts .. "/rofi-screenshot.sh",
        power      = scripts .. "/rofi-power.sh",
        utilities  = scripts .. "/rofi-utilities.sh",
        help       = scripts .. "/rofi-help.sh",
        caffeine   = scripts .. "/caffeine.sh",
    },
}
