pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import qs.services
import qs.utils

// Open windows for the launcher's "windows" mode (Super+Tab), most recently
// focused first, so the second row is the window you were just in.
Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}windows `.length);
    }

    // The window that had focus when the list opened, to go back to on Esc.
    property string origin
    property bool chosen

    function begin(): void {
        origin = Hypr.activeToplevel?.address ?? "";
        chosen = false;
    }

    function focusWindow(address: string): void {
        Hypr.dispatch(Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${address}" })` : `focuswindow address:0x${address}`);
    }

    // Closed without picking anything: put things back.
    function restore(): void {
        if (!chosen && origin)
            focusWindow(origin);
    }

    list: variants.instances
    key: "search"

    Variants {
        id: variants

        model: Hypr.toplevels.values.filter(t => t.workspace).sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 999) - (b.lastIpcObject?.focusHistoryID ?? 999))

        Win {}
    }

    component Win: QtObject {
        required property HyprlandToplevel modelData
        readonly property string title: modelData.title || modelData.lastIpcObject?.title || ""
        readonly property string appClass: modelData.lastIpcObject?.class ?? ""
        readonly property string workspace: {
            const name = modelData.workspace?.name ?? "";
            return name.startsWith("special:") ? name.slice(8) : name;
        }
        readonly property bool special: (modelData.workspace?.name ?? "").startsWith("special:")
        readonly property string icon: Icons.getAppIcon(appClass, "image-missing")
        readonly property string search: `${title} ${appClass}`

        // Called as the highlight moves over this row.
        function preview(): void {
            root.focusWindow(modelData.address);
        }

        function onClicked(list: AppList): void {
            root.chosen = true;
            list.screenState.launcher = false;
            // Closing the launcher hands keyboard focus back to the previous window,
            // so focus the chosen one just after that (this also switches to its workspace).
            const request = Hypr.usingLua ? `hl.dsp.focus({ window = "address:0x${modelData.address}" })` : `focuswindow address:0x${modelData.address}`;
            Quickshell.execDetached(["sh", "-c", "sleep 0.15; exec hyprctl dispatch \"$0\"", request]);
        }
    }
}
