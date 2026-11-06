import Quickshell.Io
import Quickshell.Services.Pipewire

// left = mixer · right = mute · scroll = volume
Widget {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinkAudio: sink ? sink.audio : null
    readonly property bool muted: sinkAudio ? sinkAudio.muted : false
    readonly property int volume: sinkAudio ? Math.round(sinkAudio.volume * 100) : 0

    // Pipewire objects only emit live updates while tracked.
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    text: {
        if (muted) return Theme.iconVolumeMuted;
        if (volume >= 66) return Theme.iconsVolume[2];
        if (volume >= 33) return Theme.iconsVolume[1];
        return Theme.iconsVolume[0];
    }

    dimmed: muted
    tooltip: {
        const name = root.sink ? (root.sink.description || root.sink.name) : "No output";
        return `${name}\n${muted ? "Muted" : volume + "%"}\nScroll to change · right click to mute`;
    }

    onActivated: button => {
        if (button === Qt.RightButton) {
            if (root.sinkAudio) root.sinkAudio.muted = !root.sinkAudio.muted;
        } else {
            mixer.running = true;
        }
    }

    onWheel: delta => {
        if (!root.sinkAudio) return;
        const next = root.sinkAudio.volume + (delta > 0 ? 0.05 : -0.05);
        root.sinkAudio.volume = Math.max(0, Math.min(1, next));
    }

    Process {
        id: mixer
        command: ["pavucontrol"]
    }
}
