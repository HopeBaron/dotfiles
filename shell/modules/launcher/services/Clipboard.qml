pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

// Clipboard history (cliphist) for the launcher's "clipboard" mode.
Searcher {
    id: root

    property var entries: []

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}clipboard `.length);
    }

    function reload(): void {
        getList.running = true;
    }

    list: items.instances
    key: "text"

    Variants {
        id: items

        model: root.entries

        Entry {}
    }

    Process {
        id: getList

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    const tab = line.indexOf("\t");
                    if (tab < 1)
                        continue;
                    const id = line.slice(0, tab);
                    const body = line.slice(tab + 1);
                    // cliphist lists images as "[[ binary data 12 KiB png 800x600 ]]"
                    const image = /^\[\[ binary data (.*) \]\]$/.exec(body);
                    out.push({
                        id,
                        image: image !== null,
                        text: image ? image[1] : body.replace(/\s+/g, " ").trim()
                    });
                }
                root.entries = out;
            }
        }
    }

    component Entry: QtObject {
        required property var modelData
        readonly property string id: modelData.id
        readonly property bool image: modelData.image
        readonly property string text: modelData.text
        // Only digits are ever put in a command line.
        readonly property bool valid: /^[0-9]+$/.test(id)

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            if (valid)
                Quickshell.execDetached(["sh", "-c", `cliphist decode ${id} | wl-copy`]);
        }

        function remove(): void {
            if (!valid)
                return;
            Quickshell.execDetached(["sh", "-c", `cliphist list | grep -m1 -P '^${id}\\t' | cliphist delete`]);
            root.entries = root.entries.filter(e => e.id !== id);
        }
    }
}
