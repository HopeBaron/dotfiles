pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import qs.utils

// Keybind cheatsheet shown by the launcher's "shortcut" mode (Super+Shift+/).
// Hand-maintained: keep in step with hypr/hyprland/keybinds.lua and variables.lua.
Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}shortcut `.length);
    }

    function selector(item: var): string {
        return `${item.name} ${item.keys} ${item.section}`;
    }

    list: [
        Key {
            section: "Core"
            keys: "Super (tap)"
            name: "Launcher"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+Tab"
            name: "Open windows"
            run: "hl.dsp.global(\"caelestia:windows\")"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+T"
            name: "Terminal"
            run: "hl.dsp.exec_cmd(require(\"variables\").terminal)"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+W"
            name: "Browser"
            run: "hl.dsp.exec_cmd(require(\"variables\").browser)"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+C"
            name: "Editor"
            run: "hl.dsp.exec_cmd(require(\"variables\").editor)"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+E"
            name: "File explorer"
            run: "hl.dsp.exec_cmd(require(\"variables\").fileExplorer)"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+Q"
            name: "Close window"
            run: "hl.dsp.window.close()"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+F"
            name: "Fullscreen"
            run: "hl.dsp.window.fullscreen({ mode = \"fullscreen\" })"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+Alt+F"
            name: "Maximize with borders"
            run: "hl.dsp.window.fullscreen({ mode = \"maximized\" })"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+Alt+Space"
            name: "Toggle floating"
            run: "hl.dsp.window.float()"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+P"
            name: "Pin window"
            run: "hl.dsp.window.pin()"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+L"
            name: "Lock"
            run: "hl.dsp.global(\"caelestia:lock\")"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+Shift+L"
            name: "Sleep"
            run: "hl.dsp.exec_cmd(require(\"variables\").sleepGestureCmd)"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Ctrl+Alt+Delete"
            name: "Session menu"
            run: "hl.dsp.global(\"caelestia:session\")"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+N"
            name: "Sidebar / notifications"
            run: "hl.dsp.global(\"caelestia:sidebar\")"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+K"
            name: "Show all panels"
            run: "hl.dsp.global(\"caelestia:showall\")"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Ctrl+Alt+C"
            name: "Clear notifications"
            run: "hl.dsp.global(\"caelestia:clearNotifs\")"
            icon: "keyboard"
        },
        Key {
            section: "Core"
            keys: "Super+Shift+/"
            name: "This cheatsheet"
            icon: "keyboard"
        },
        Key {
            section: "Windows"
            keys: "Super+Arrows"
            name: "Focus direction"
            icon: "web_asset"
        },
        Key {
            section: "Windows"
            keys: "Super+Shift+Arrows"
            name: "Move window"
            icon: "web_asset"
        },
        Key {
            section: "Windows"
            keys: "Super+Alt+Arrows"
            name: "Resize window"
            icon: "web_asset"
        },
        Key {
            section: "Windows"
            keys: "Super+Minus / Equal"
            name: "Narrower / wider"
            icon: "web_asset"
        },
        Key {
            section: "Windows"
            keys: "Super+Z + drag"
            name: "Move window"
            icon: "web_asset"
        },
        Key {
            section: "Windows"
            keys: "Super+X + drag"
            name: "Resize window"
            icon: "web_asset"
        },
        Key {
            section: "Windows"
            keys: "Ctrl+Super+Backslash"
            name: "Center window"
            run: "hl.dsp.window.center()"
            icon: "web_asset"
        },
        Key {
            section: "Windows"
            keys: "Super+Alt+Backslash"
            name: "Picture-in-picture"
            icon: "web_asset"
        },
        Key {
            section: "Windows"
            keys: "Alt+Tab"
            name: "Cycle windows"
            run: "hl.dsp.window.cycle_next()"
            icon: "web_asset"
        },
        Key {
            section: "Workspaces"
            keys: "Super+1..0"
            name: "Go to workspace"
            icon: "workspaces"
        },
        Key {
            section: "Workspaces"
            keys: "Super+Alt+1..0"
            name: "Move window to workspace"
            icon: "workspaces"
        },
        Key {
            section: "Workspaces"
            keys: "Super+Shift+1..0"
            name: "Move window silently"
            icon: "workspaces"
        },
        Key {
            section: "Workspaces"
            keys: "Super+Page Up/Down"
            name: "Previous / next workspace"
            icon: "workspaces"
        },
        Key {
            section: "GROUPS (tabs)"
            keys: "Super+,"
            name: "Toggle group"
            run: "hl.dsp.group.toggle()"
            icon: "tab"
        },
        Key {
            section: "GROUPS (tabs)"
            keys: "Super+Shift+,"
            name: "Lock group"
            run: "hl.dsp.group.lock_active()"
            icon: "tab"
        },
        Key {
            section: "GROUPS (tabs)"
            keys: "Super+U"
            name: "Ungroup"
            run: "hl.dsp.window.move({ out_of_group = true })"
            icon: "tab"
        },
        Key {
            section: "GROUPS (tabs)"
            keys: "Ctrl+Alt+Tab"
            name: "Next window in group"
            run: "hl.dsp.group.next()"
            icon: "tab"
        },
        Key {
            section: "Scratchpads"
            keys: "Super+S"
            name: "Special workspace"
            run: "require(\"utils.functions\").toggle(\"specialws\")()"
            icon: "dashboard"
        },
        Key {
            section: "Scratchpads"
            keys: "Super+Alt+S"
            name: "Move window to it"
            run: "hl.dsp.window.move({ workspace = \"special:special\" })"
            icon: "dashboard"
        },
        Key {
            section: "Scratchpads"
            keys: "Super+M"
            name: "Music"
            run: "require(\"utils.functions\").toggle(\"music\")()"
            icon: "dashboard"
        },
        Key {
            section: "Scratchpads"
            keys: "Super+D"
            name: "Communication"
            run: "require(\"utils.functions\").toggle(\"communication\")()"
            icon: "dashboard"
        },
        Key {
            section: "Scratchpads"
            keys: "Super+R"
            name: "Todo"
            run: "require(\"utils.functions\").toggle(\"todo\")()"
            icon: "dashboard"
        },
        Key {
            section: "Scratchpads"
            keys: "Ctrl+Shift+Esc"
            name: "System monitor"
            run: "require(\"utils.functions\").toggle(\"sysmon\")()"
            icon: "dashboard"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Print"
            name: "Screenshot"
            run: "hl.dsp.exec_cmd(\"caelestia screenshot\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Super+Shift+S"
            name: "Freeze-frame screenshot"
            run: "hl.dsp.global(\"caelestia:screenshotFreeze\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Super+Shift+Alt+S"
            name: "Region screenshot"
            run: "hl.dsp.global(\"caelestia:screenshot\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Ctrl+Alt+R"
            name: "Record"
            run: "hl.dsp.exec_cmd(\"caelestia record\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Super+Alt+R"
            name: "Record with sound"
            run: "hl.dsp.exec_cmd(\"caelestia record -s\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Super+Shift+Alt+R"
            name: "Record a region"
            run: "hl.dsp.exec_cmd(\"caelestia record -r\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Super+Shift+C"
            name: "Color picker"
            run: "hl.dsp.exec_cmd(\"hyprpicker -a\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Super+V"
            name: "Clipboard history"
            run: "hl.dsp.global(\"caelestia:clipboard\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Super+."
            name: "Emoji picker"
            run: "hl.dsp.exec_cmd(\"pkill fuzzel || caelestia emoji -p\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Capture / Clipboard / Media"
            keys: "Ctrl+Super+Space"
            name: "Play / pause"
            run: "hl.dsp.global(\"caelestia:mediaToggle\")"
            icon: "screenshot_region"
        },
        Key {
            section: "Ctrl+Super+Equal/Minus Next / previous track"
            keys: "Super+Shift+M"
            name: "Mute"
            run: "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle\")"
            icon: "keyboard"
        },
        Key {
            section: "Shell Recovery"
            keys: "Ctrl+Super+Alt+R"
            name: "Restart shell"
            run: "hl.dsp.exec_cmd(\"qs -c caelestia kill; sleep .1; caelestia shell -d\")"
            icon: "restart_alt"
        },
        Key {
            section: "Shell Recovery"
            keys: "Ctrl+Super+Shift+R"
            name: "Kill shell"
            run: "hl.dsp.exec_cmd(\"qs -c caelestia kill\")"
            icon: "restart_alt"
        },
        Key {
            section: "Shell Recovery"
            keys: "Super+Alt+L"
            name: "Restore lock screen"
            icon: "restart_alt"
        }
    ]

    component Key: QtObject {
        property string section
        property string keys
        property string name
        property string icon
        // A Lua expression for `hyprctl dispatch`; empty for rows that only describe a key.
        property string run
        readonly property string desc: section

        function onClicked(list: AppList): void {
            if (!run)
                return;
            list.screenState.launcher = false;
            // Wait for the launcher to close so the action lands on the window underneath.
            Quickshell.execDetached(["sh", "-c", "sleep 0.3; exec hyprctl dispatch \"$0\"", run]);
        }
    }
}
