pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Keep-awake toggle. Off (the default) leaves hypridle's timers alone: dim,
// lock, screen off, suspend. On holds a systemd idle inhibitor, which hypridle
// honours, so none of them fire. Lock-before-sleep still works either way.
//
// Toggle from anywhere: qs ipc call idle toggle
Singleton {
    id: root

    property bool keepAwake: false

    function toggle() {
        keepAwake = !keepAwake;
    }

    // Killing the process releases the inhibitor, so it can never leak past
    // Quickshell exiting.
    Process {
        running: root.keepAwake
        command: ["systemd-inhibit", "--what=idle", "--who=Quickshell",
            "--why=Keep awake toggle", "--mode=block", "sleep", "infinity"]

        onExited: root.keepAwake = false
    }

    IpcHandler {
        target: "idle"

        function toggle(): void { root.toggle(); }
        function on(): void { root.keepAwake = true; }
        function off(): void { root.keepAwake = false; }
        function status(): string { return root.keepAwake ? "awake" : "idle"; }
    }
}
