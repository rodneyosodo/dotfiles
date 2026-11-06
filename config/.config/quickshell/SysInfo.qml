pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Polls /proc, /sys and df for the cpu, memory, disk and temperature readouts.
// CPU usage is a delta between two polls, so the first sample reads 0%.
Singleton {
    id: root

    property int cpuPercent: 0
    property int memPercent: 0
    property int diskPercent: 0
    property int tempC: 0

    property real memUsedGiB: 0
    property real memTotalGiB: 0
    property string diskUsed: ""
    property string diskTotal: ""

    property real _prevBusy: -1
    property real _prevTotal: -1

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statProc.running = true
    }

    Process {
        id: statProc
        command: ["sh", "-c",
            "awk '/^cpu /{b=$2+$3+$4+$7+$8; t=$2+$3+$4+$5+$6+$7+$8; print \"cpu\", b, t}' /proc/stat;"
            + " awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{print \"mem\", t, a}' /proc/meminfo;"
            + " df -Ph / | awk 'NR==2{gsub(/%/, \"\", $5); print \"disk\", $5, $3, $2}';"
            + " cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{print \"temp\", int($1/1000)}'"]

        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const f = line.trim().split(/\s+/);
                    if (f[0] === "cpu") {
                        const busy = parseFloat(f[1]);
                        const total = parseFloat(f[2]);
                        if (root._prevTotal >= 0 && total > root._prevTotal) {
                            const d = total - root._prevTotal;
                            root.cpuPercent = Math.max(0, Math.min(100,
                                Math.round(100 * (busy - root._prevBusy) / d)));
                        }
                        root._prevBusy = busy;
                        root._prevTotal = total;
                    } else if (f[0] === "mem") {
                        const t = parseFloat(f[1]);
                        const a = parseFloat(f[2]);
                        if (t > 0) {
                            root.memPercent = Math.round(100 * (t - a) / t);
                            root.memTotalGiB = t / 1048576;
                            root.memUsedGiB = (t - a) / 1048576;
                        }
                    } else if (f[0] === "disk") {
                        root.diskPercent = parseInt(f[1]);
                        root.diskUsed = f[2];
                        root.diskTotal = f[3];
                    } else if (f[0] === "temp") {
                        root.tempC = parseInt(f[1]);
                    }
                }
            }
        }
    }
}
