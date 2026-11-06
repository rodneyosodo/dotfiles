import QtQuick
import Quickshell
import Quickshell.Io

// left = mixer · right = mute · scroll = volume
//
// Talks to the audio server through pactl rather than Quickshell's Pipewire
// service, which sees nothing on this machine because it runs real PulseAudio.
// pactl works there and against PipeWire's Pulse server alike.
Widget {
    id: root

    property bool hasSink: false
    property string sinkName: ""
    property bool muted: false
    property int volume: 0

    text: {
        if (!hasSink) return Theme.iconVolumeMuted;
        if (muted) return Theme.iconVolumeMuted;
        let icon = Theme.iconsVolume[0];
        if (volume >= 66) icon = Theme.iconsVolume[2];
        else if (volume >= 33) icon = Theme.iconsVolume[1];
        return `${icon} ${volume}%`;
    }

    iconSlot: false
    dimmed: muted || !hasSink
    tooltip: {
        if (!hasSink) return "No output";
        return `${sinkName}\n${muted ? "Muted" : volume + "%"}\nScroll to change · right click to mute`;
    }

    function refresh() {
        if (query.running) {
            stale = true;
            return;
        }
        query.running = true;
    }

    property bool stale: false

    // First line is the default sink's name; the rest is every sink as JSON.
    Process {
        id: query
        command: ["sh", "-c", "pactl get-default-sink; pactl -f json list sinks"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const split = text.indexOf("\n");
                let sink = null;
                try {
                    const name = text.slice(0, split).trim();
                    sink = JSON.parse(text.slice(split + 1)).find(s => s.name === name) || null;
                } catch (e) {
                    sink = null;
                }

                root.hasSink = sink !== null;
                if (!sink) return;
                root.sinkName = sink.description || sink.name;
                root.muted = sink.mute;
                const first = Object.values(sink.volume)[0];
                root.volume = first ? parseInt(first.value_percent) : 0;
            }
        }

        onExited: {
            if (!root.stale) return;
            root.stale = false;
            // Deferred: the process still reports running while it signals exit.
            Qt.callLater(root.refresh);
        }
    }

    // Picks up changes from anywhere: volume keys, pavucontrol, other apps.
    Process {
        id: events
        command: ["pactl", "subscribe"]
        running: true

        stdout: SplitParser {
            onRead: line => {
                if (/ on (sink|server) /.test(line)) root.refresh();
            }
        }

        onExited: resubscribe.start()
    }

    // The audio server restarting ends the subscription.
    Timer {
        id: resubscribe
        interval: 3000
        onTriggered: {
            events.running = true;
            root.refresh();
        }
    }

    onActivated: button => {
        if (button === Qt.RightButton)
            Quickshell.execDetached(["pactl", "set-sink-mute", "@DEFAULT_SINK@", "toggle"]);
        else
            Quickshell.execDetached(["pavucontrol"]);
    }

    // A wheel notch (120) is one 5% step; touchpad deltas add up to the same.
    property real wheelAccumulator: 0

    onWheel: delta => {
        if (!hasSink) return;
        wheelAccumulator += delta;
        const steps = Math.trunc(wheelAccumulator / 120);
        if (steps === 0) return;
        wheelAccumulator -= steps * 120;
        // Updated here too, so fast scrolling steps from the latest value.
        root.volume = Math.max(0, Math.min(100, root.volume + steps * 5));
        Quickshell.execDetached(["pactl", "set-sink-volume", "@DEFAULT_SINK@", `${root.volume}%`]);
    }
}
