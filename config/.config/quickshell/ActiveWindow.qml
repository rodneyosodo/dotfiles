import QtQuick
import Quickshell.Hyprland
import Quickshell.Io

// Title of the focused window, as Omarchy's bar shows.
//
// Quickshell 0.3.2 only learns the focused window from a focus-change event, so
// Hyprland.activeToplevel stays null after startup until focus next moves.
// Asking hyprctl gives the right answer straight away.
Widget {
    id: root

    property string title: ""
    property bool stale: false

    function refresh() {
        if (query.running) {
            stale = true;
            return;
        }
        query.running = true;
    }

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const name = event ? String(event.name) : "";
            if (name.startsWith("activewindow") || name.startsWith("windowtitle")
                || name.startsWith("workspace") || name === "closewindow") {
                root.refresh();
            }
        }
    }

    Process {
        id: query
        command: ["hyprctl", "activewindow", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.title = JSON.parse(text).title || "";
                } catch (e) {
                    root.title = "";
                }
            }
        }

        onExited: {
            if (!root.stale) return;
            root.stale = false;
            // Deferred: the process still reports running while it signals exit.
            Qt.callLater(root.refresh);
        }
    }

    text: title
    maxWidth: 420
    iconSlot: false
    dimmed: true
    interactive: false
    tooltip: title
}
