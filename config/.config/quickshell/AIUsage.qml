pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// AI plan usage (Claude, OpenCode Go) from ai-usagebar, which reuses the CLIs'
// own logins; see ~/.config/ai-usagebar/config.toml for which vendors are on.
//
// One fetch for every bar, every 2 minutes. ai-usagebar caches and backs off
// on rate limits itself, and keeps the last good numbers on network errors.
Singleton {
    id: root

    // [{ id, name, plan, percent (highest window), metrics, error, stale }]
    property var entries: []
    property bool available: true
    property date updated
    readonly property bool loading: proc.running

    // The usage card under the bar item.
    property bool cardOpen: false

    function toggleCard() {
        cardOpen = !cardOpen;
        if (cardOpen) refresh();
    }

    function refresh() {
        if (!proc.running) proc.running = true;
    }

    IpcHandler {
        target: "aiusage"

        function toggle(): void { root.toggleCard(); }
        function open(): void { root.cardOpen = true; root.refresh(); }
        function close(): void { root.cardOpen = false; }
        function refresh(): void { root.refresh(); }
    }

    function apply(text) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return;
        }

        entries = (data.entries || []).map(e => {
            // The headline is whichever limit window is closest to running
            // out. Metrics without a reset (extra-usage spend) don't count.
            const windows = (e.metrics || []).filter(m => m.reset_at && typeof m.percent === "number");
            const percent = windows.length ? Math.max(...windows.map(m => m.percent)) : -1;
            return {
                id: e.id,
                name: e.display_name || e.name,
                plan: e.plan || "",
                percent: percent,
                metrics: e.metrics || [],
                error: e.error || "",
                stale: !!e.stale
            };
        });
        updated = new Date();
    }

    Process {
        id: proc
        command: ["ai-usagebar", "usage", "--json"]

        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }

        // Exit 127: not installed (cargo install --locked ai-usagebar).
        onExited: code => root.available = code !== 127
    }

    Timer {
        interval: 2 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
