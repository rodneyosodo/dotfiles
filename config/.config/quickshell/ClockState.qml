pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// State behind the clock popup: whether it is open, and the time zones it
// converts between.
//
// Zones come from zones.json beside this file, a list of IANA names or
// { "zone": ..., "label": ... } objects. The home zone is never listed: it is
// read from timedatectl, so it is always this machine's real zone.
//
// QML's JavaScript has no time-zone database, so offsets come from `date`,
// asked once per zone when the popup opens and every half hour after.
//
// Toggle from anywhere: qs ipc call clock toggle
Singleton {
    id: root

    property bool open: false

    function toggle() {
        open = !open;
    }

    // Zones from zones.json: [{ zone, label }].
    property var configured: []

    // Every row the popup shows, home included, sorted west to east:
    // [{ zone, label, offset (minutes from UTC), abbr, home }].
    property var rows: []

    // Home zone's offset; falls back to what JavaScript reports for local time.
    property int homeOffset: -new Date().getTimezoneOffset()

    // Unknown zone names, so the popup can say which ones it skipped.
    property var invalid: []

    function labelFor(zone) {
        const last = String(zone).split("/").pop();
        return last.replace(/_/g, " ");
    }

    function parseConfig(text) {
        let list = [];
        try {
            const parsed = JSON.parse(text);
            if (Array.isArray(parsed)) list = parsed;
        } catch (e) {
            console.warn("zones.json:", e);
        }

        const out = [];
        for (const entry of list) {
            const zone = typeof entry === "string" ? entry : (entry && entry.zone);
            if (!zone) continue;
            const label = (entry && entry.label) || labelFor(zone);
            out.push({ zone: String(zone), label: String(label) });
        }
        configured = out;
        refresh();
    }

    function parseOffset(value) {
        const m = /^([+-])(\d\d)(\d\d)$/.exec(String(value).trim());
        if (!m) return 0;
        const minutes = parseInt(m[2], 10) * 60 + parseInt(m[3], 10);
        return m[1] === "-" ? -minutes : minutes;
    }

    function applyOffsets(text) {
        const lines = text.split("\n").filter(l => l !== "");
        if (lines.length === 0) return;

        const out = [];
        const bad = [];
        const seen = {};

        lines.forEach((line, i) => {
            const [zone, offset, abbr, ok] = line.split("|");
            const home = i === 0;
            if (ok !== "1") {
                if (!home) bad.push(zone);
                return;
            }
            if (seen[zone]) return;
            seen[zone] = true;

            const entry = home ? null : root.configured.find(z => z.zone === zone);
            out.push({
                zone: zone,
                label: entry ? entry.label : root.labelFor(zone),
                offset: root.parseOffset(offset),
                abbr: abbr,
                home: home
            });
            if (home) root.homeOffset = root.parseOffset(offset);
        });

        out.sort((a, b) => a.offset - b.offset || (a.home ? -1 : b.home ? 1 : 0));
        rows = out;
        invalid = bad;
    }

    function refresh() {
        if (tzProc.running) {
            stale = true;
            return;
        }
        tzProc.command = ["sh", "-c", tzScript, "sh"].concat(configured.map(z => z.zone));
        tzProc.running = true;
    }

    property bool stale: false

    // First line is the home zone. Each line: zone|+hhmm|ABBR|1, or zone|||0
    // when the name isn't in the zone database (date would quietly use UTC).
    readonly property string tzScript: `
        home=$(timedatectl show -p Timezone --value 2>/dev/null)
        [ -n "$home" ] || home=$(readlink /etc/localtime | sed 's|.*/zoneinfo/||')
        for z in "$home" "$@"; do
            case "$z" in ""|/*|*..*) printf '%s|||0\\n' "$z"; continue ;; esac
            if [ -f "/usr/share/zoneinfo/$z" ]; then
                printf '%s|%s|%s|1\\n' "$z" "$(TZ=$z date +%z)" "$(TZ=$z date +%Z)"
            else
                printf '%s|||0\\n' "$z"
            fi
        done`

    Process {
        id: tzProc

        stdout: StdioCollector {
            onStreamFinished: root.applyOffsets(text)
        }

        onExited: {
            if (!root.stale) return;
            root.stale = false;
            Qt.callLater(root.refresh);
        }
    }

    // Daylight saving moves offsets; this keeps an open popup honest.
    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    onOpenChanged: if (open) refresh()

    FileView {
        path: Quickshell.shellPath("zones.json")
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseConfig(text())
        onLoadFailed: root.parseConfig("[]")
    }

    IpcHandler {
        target: "clock"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open = true; }
        function close(): void { root.open = false; }
    }
}
