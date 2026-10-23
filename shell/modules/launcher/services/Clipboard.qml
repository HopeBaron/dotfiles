pragma Singleton

import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

// Clipboard history (cliphist) for the launcher's "clipboard" mode, with pinned
// clips kept above it. Pins are stored by us (cliphist has no such thing) in
// clipboard-pins.json, with pinned images copied next to it, so they outlive
// cliphist's own history.
Searcher {
    id: root

    property var history: []
    property var pins: []
    property bool pinsLoaded

    // Pinned clips first, then history without the entries already pinned.
    readonly property var entries: {
        const pinned = pins.map((p, i) => ({
                    id: `pin${i}`,
                    pinned: true,
                    image: p.kind === "image",
                    text: p.kind === "image" ? p.info : normalise(p.text),
                    full: p.text ?? "",
                    file: p.file ?? ""
                }));
        const texts = pins.filter(p => p.kind === "text").map(p => normalise(p.text));
        // cliphist shortens long clips with a trailing "…".
        const isPinned = h => !h.image && texts.some(t => t === h.text || (h.text.endsWith("…") && t.startsWith(h.text.slice(0, -1))));
        return [...pinned, ...history.filter(h => !isPinned(h))];
    }

    // The focused image entry, decoded to a file the preview can load. History
    // images are decoded under the runtime dir (tmpfs, gone at logout); pinned
    // ones already have a file.
    property string previewId
    property bool previewReady
    property string previewFile
    property bool previewExpanded
    readonly property string previewSource: previewReady && previewFile ? `file://${previewFile}` : ""
    readonly property string previewDir: `${Quickshell.env("XDG_RUNTIME_DIR") ?? "/tmp"}/caelestia-clipboard`
    readonly property string pinsDir: `${Paths.state}/clipboard-pins`

    function normalise(text: string): string {
        return (text ?? "").replace(/\s+/g, " ").trim();
    }

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}clipboard `.length);
    }

    function preview(entry: var): void {
        if (!entry || !entry.image)
            return;
        if (entry.pinned) {
            previewId = entry.id;
            previewFile = entry.file;
            previewReady = true;
            return;
        }
        // Only digits are ever put in a command line.
        if (!/^[0-9]+$/.test(entry.id)) {
            previewReady = false;
            return;
        }
        if (entry.id === previewId && previewReady)
            return;
        previewReady = false;
        previewId = entry.id;
        previewFile = `${previewDir}/${entry.id}`;
        decode.command = ["sh", "-c", `mkdir -p "${previewDir}" && { [ -s "${previewDir}/${entry.id}" ] || cliphist decode ${entry.id} > "${previewDir}/${entry.id}"; }`];
        decode.running = true;
    }

    function reload(): void {
        getList.running = true;
    }

    // Empties the history and the clipboard itself. Pins stay.
    function wipe(): void {
        Quickshell.execDetached(["sh", "-c", `cliphist wipe; wl-copy --clear; rm -rf "${previewDir}"`]);
        history = [];
        previewReady = false;
        previewId = "";
    }

    function savePins(): void {
        storage.setText(JSON.stringify(pins));
    }

    function unpin(index: int): void {
        const pin = pins[index];
        if (!pin)
            return;
        if (pin.kind === "image" && pin.file)
            Quickshell.execDetached(["rm", "-f", pin.file]);
        pins = pins.filter((_, i) => i !== index);
        savePins();
    }

    function pin(entry: var): void {
        if (capturing || !/^[0-9]+$/.test(entry.id))
            return;
        capturing = true;
        captureEntry = entry;
        if (entry.image) {
            const file = `${pinsDir}/${Date.now()}.png`;
            captureFile = file;
            captureImage.command = ["sh", "-c", `mkdir -p "${pinsDir}" && cliphist decode ${entry.id} > "${file}"`];
            captureImage.running = true;
        } else {
            captureText.command = ["cliphist", "decode", entry.id];
            captureText.running = true;
        }
    }

    property bool capturing
    property var captureEntry: null
    property string captureFile

    list: items.instances
    key: "text"

    Variants {
        id: items

        model: root.entries

        Entry {}
    }

    FileView {
        id: storage

        printErrors: false
        path: `${Paths.state}/clipboard-pins.json`
        onLoaded: {
            try {
                root.pins = JSON.parse(text());
            } catch (e) {
                root.pins = [];
            }
            root.pinsLoaded = true;
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound)
                root.pinsLoaded = true;
        }
    }

    Process {
        id: decode

        onExited: code => root.previewReady = code === 0
    }

    Process {
        id: captureText

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length > 0)
                    root.pins = [...root.pins, {
                            kind: "text",
                            text: text
                        }];
                root.savePins();
            }
        }
        onExited: root.capturing = false
    }

    Process {
        id: captureImage

        onExited: code => {
            if (code === 0) {
                root.pins = [...root.pins, {
                        kind: "image",
                        file: root.captureFile,
                        info: root.captureEntry?.text ?? ""
                    }];
                root.savePins();
            }
            root.capturing = false;
        }
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
                        pinned: false,
                        image: image !== null,
                        text: image ? image[1] : root.normalise(body),
                        full: "",
                        file: ""
                    });
                }
                root.history = out;
            }
        }
    }

    component Entry: QtObject {
        required property var modelData
        readonly property string id: modelData.id
        readonly property bool pinned: modelData.pinned
        readonly property bool image: modelData.image
        readonly property string text: modelData.text
        readonly property string full: modelData.full
        readonly property string file: modelData.file
        // Only digits are ever put in a command line.
        readonly property bool valid: /^[0-9]+$/.test(id)

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            if (pinned) {
                if (image)
                    Quickshell.execDetached(["sh", "-c", 'wl-copy < "$0"', modelData.file]);
                else
                    Quickshell.execDetached(["sh", "-c", 'printf %s "$0" | wl-copy', modelData.full]);
            } else if (valid) {
                Quickshell.execDetached(["sh", "-c", `cliphist decode ${id} | wl-copy`]);
            }
        }

        function togglePin(): void {
            if (pinned)
                root.unpin(parseInt(id.slice(3)));
            else
                root.pin({
                    id: id,
                    image: image,
                    text: text
                });
        }

        function remove(): void {
            if (!valid || pinned)
                return;
            Quickshell.execDetached(["sh", "-c", `cliphist list | grep -m1 -P '^${id}\\t' | cliphist delete`]);
            root.history = root.history.filter(e => e.id !== id);
        }
    }
}
