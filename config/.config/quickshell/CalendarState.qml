pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Read-only calendar sync for the clock popup.
//
// Feeds live in ~/.config/quickshell-calendars.json, deliberately outside the
// dotfiles: a private iCal address is a credential. scripts/calendar-sync.py
// fetches them and prints the events; this keeps them grouped by day.
//
// Syncs at startup, every 15 minutes, when the feed file changes, and when
// the popup opens if the last sync is over 5 minutes old.
Singleton {
    id: root

    readonly property string feedsPath: Quickshell.env("HOME") + "/.config/quickshell-calendars.json"

    // At least one feed has a URL. The popup only shows events and the
    // agenda when this is true.
    property bool enabled: false
    property bool syncing: sync.running
    property string updated: ""
    property var feeds: []          // [{ name, color, ok, error, count }]
    property var byDay: ({})        // "yyyy-MM-dd" -> [event]
    property real lastSync: 0

    readonly property var failed: feeds.filter(f => !f.ok)

    function key(date) {
        return Qt.formatDate(date, "yyyy-MM-dd");
    }

    function eventsOn(date) {
        return byDay[key(date)] || [];
    }

    // Local wall-clock "yyyy-MM-ddTHH:mm" or "yyyy-MM-dd" to a Date.
    function parse(text) {
        const m = /^(\d{4})-(\d\d)-(\d\d)(?:T(\d\d):(\d\d))?$/.exec(text);
        if (!m) return null;
        return new Date(+m[1], +m[2] - 1, +m[3], +(m[4] || 0), +(m[5] || 0));
    }

    function refresh() {
        if (sync.running) {
            stale = true;
            return;
        }
        sync.running = true;
    }

    function refreshIfOld() {
        if (enabled && Date.now() - lastSync > 5 * 60 * 1000) refresh();
    }

    property bool stale: false

    function apply(text) {
        let data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            console.warn("calendar-sync: bad output", e);
            return;
        }

        const days = {};
        for (const ev of data.events || []) {
            const start = parse(ev.start);
            const end = parse(ev.end);
            if (!start || !end) continue;
            ev.startDate = start;
            ev.endDate = end;

            // List the event on every day it touches. All-day ends are
            // exclusive; a timed event ending at midnight doesn't spill over.
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate());
            let guard = 0;
            do {
                const k = key(d);
                (days[k] = days[k] || []).push(ev);
                d.setDate(d.getDate() + 1);
            } while (d < end && guard++ < 62);
        }

        byDay = days;
        feeds = data.feeds || [];
        enabled = (data.configured || 0) > 0;
        updated = data.updated || "";
        lastSync = Date.now();
    }

    Process {
        id: sync
        command: ["python3", "-I", Quickshell.shellPath("scripts/calendar-sync.py")]

        stdout: StdioCollector {
            onStreamFinished: root.apply(text)
        }

        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn("calendar-sync:", text.trim())
        }

        onExited: {
            if (!root.stale) return;
            root.stale = false;
            Qt.callLater(root.refresh);
        }
    }

    Timer {
        interval: 15 * 60 * 1000
        running: root.enabled
        repeat: true
        onTriggered: root.refresh()
    }

    // Edits to the feed file apply straight away. printErrors is off: the
    // file not existing just means sync was never set up.
    FileView {
        path: root.feedsPath
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            root.refresh();
        }
    }

    Component.onCompleted: refresh()
}
