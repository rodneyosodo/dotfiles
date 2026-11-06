import QtQuick
import Quickshell
import Quickshell.Hyprland

// Workspace switcher, following Omarchy's: workspaces are numbered, the one
// on screen shows a layout glyph instead of its number, empty ones are dimmed,
// and the wheel steps along the row.
//
// Hyprland 0.57 parses `hyprctl dispatch` as Lua, so dispatches use the
// hl.dsp.* form; the plain "workspace N" string is rejected.
Row {
    id: root

    readonly property int persistentCount: 5
    readonly property var live: Hyprland.workspaces.values

    // Each bar belongs to one monitor, so it shows that monitor's workspaces.
    readonly property var monitor: {
        const window = root.QsWindow.window;
        const screen = window ? window.screen : null;
        return screen ? Hyprland.monitorFor(screen) : Hyprland.focusedMonitor;
    }

    readonly property int activeId: monitor && monitor.activeWorkspace
        ? monitor.activeWorkspace.id
        : -1

    readonly property var ids: {
        const out = [];
        for (let i = 1; i <= persistentCount; i++) out.push(i);
        for (const ws of live) {
            if (ws.id > 0 && !out.includes(ws.id)) out.push(ws.id);
        }
        return out.sort((a, b) => a - b);
    }

    function workspaceById(id) {
        for (const ws of live) {
            if (ws.id === id) return ws;
        }
        return null;
    }

    function focusWorkspace(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    // A wheel notch moves one along the row; touchpad deltas accumulate.
    property real wheelAccumulator: 0

    function step(delta) {
        wheelAccumulator += delta;
        const steps = Math.trunc(wheelAccumulator / 120);
        if (steps === 0) return;
        wheelAccumulator -= steps * 120;

        const index = ids.indexOf(activeId);
        if (index === -1) return;
        // Holds at either end rather than wrapping.
        const target = ids[Math.max(0, Math.min(ids.length - 1, index - steps))];
        if (target !== activeId) focusWorkspace(target);
    }

    spacing: 0

    Repeater {
        model: root.ids

        Widget {
            required property int modelData

            readonly property var workspace: root.workspaceById(modelData)
            readonly property bool occupied: workspace !== null && workspace.toplevels.values.length > 0
            readonly property bool shown: modelData === root.activeId

            // The workspace on screen carries a layout glyph rather than a number.
            text: shown ? Theme.iconWorkspaceActive : (modelData === 10 ? "0" : String(modelData))
            iconSlot: true
            color: shown ? Theme.accent : Theme.foreground
            dimmed: !occupied && !shown
            tooltip: {
                const n = workspace ? workspace.toplevels.values.length : 0;
                if (shown) return `Workspace ${modelData} — on screen`;
                return n > 0
                    ? `Workspace ${modelData} — ${n} window${n === 1 ? "" : "s"}`
                    : `Workspace ${modelData} — empty`;
            }

            onActivated: root.focusWorkspace(modelData)
            onWheel: delta => root.step(delta)
        }
    }
}
