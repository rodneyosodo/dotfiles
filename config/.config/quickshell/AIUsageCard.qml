import QtQuick
import Quickshell
import Quickshell.Wayland

// Usage card for the AI plans, styled after omarchy-ai-usage (CodeNotch):
// per provider, one row per limit window with its reset, a bar of percent
// used, a marker where an even burn rate would be by now, and a one-line
// verdict on whether the limit lasts until the reset.
//
// Same layer-shell setup as the clock popup: a panel on the overlay layer,
// and a transparent full-screen layer behind it that closes it on a click
// anywhere else. Esc closes it too.
PanelWindow {
    id: root

    // Window x of the AI slots' right edge, so the card lines up under them.
    property real anchorRight: 0
    property var iconFor: entry => ""

    anchors.top: true
    anchors.right: true
    margins.top: Theme.barHeight + 4
    margins.right: {
        const w = screen ? screen.width : 1920;
        const right = anchorRight > 0 ? w - anchorRight : Theme.sideMargin;
        return Math.max(Theme.sideMargin, Math.min(right, w - implicitWidth - Theme.sideMargin));
    }
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-aiusage"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 2 * pad
    color: "transparent"

    readonly property int pad: 16
    readonly property color dim: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.5)
    readonly property color track: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.12)

    // Ticks so "resets in" and the pace marker move while it is open.
    property date now: new Date()

    Timer {
        interval: 30000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    onVisibleChanged: {
        if (visible) {
            now = new Date();
            keys.forceActiveFocus();
        }
    }

    // ---- time helpers ----

    function duration(secs) {
        secs = Math.max(0, Math.round(secs));
        const d = Math.floor(secs / 86400);
        const h = Math.floor(secs % 86400 / 3600);
        const m = Math.floor(secs % 3600 / 60);
        if (d > 0) return h ? `${d}d ${h}h` : `${d}d`;
        if (h > 0) return m ? `${h}h ${m}m` : `${h}h`;
        return `${Math.max(1, m)} min`;
    }

    function resetText(metric) {
        if (!metric.reset_at) return "";
        const reset = new Date(metric.reset_at);
        const secs = (reset - now) / 1000;
        if (secs <= 0) return "Resetting";
        if (secs < 86400) return `Resets in ${duration(secs)}`;
        return "Resets " + Qt.formatDateTime(reset, "ddd HH:mm");
    }

    // Window length: given for rolling windows; a monthly window without
    // one is taken as the calendar month before the reset.
    function windowSecs(metric) {
        if (metric.window_secs) return metric.window_secs;
        if (!metric.reset_at) return 0;
        const reset = new Date(metric.reset_at);
        const start = new Date(reset);
        start.setMonth(start.getMonth() - 1);
        return (reset - start) / 1000;
    }

    // Fraction of the window gone, 0-1, or -1 when unknown.
    function elapsed(metric) {
        const total = windowSecs(metric);
        if (!total || !metric.reset_at) return -1;
        const left = (new Date(metric.reset_at) - now) / 1000;
        return Math.max(0, Math.min(1, 1 - left / total));
    }

    function verdict(metric) {
        const e = elapsed(metric);
        const used = metric.percent;
        if (e < 0 || typeof used !== "number") return "";
        if (used >= 100) return "Limit reached";
        if (used <= 0) return "Unused this window";
        const total = windowSecs(metric);
        const gone = e * total;
        const left = total - gone;
        // Too early to project: a few minutes of use would read as a sprint.
        if (e < 0.1) return "";
        // Seconds until 100% at the average rate so far.
        const toLimit = (100 - used) * gone / used;
        if (toLimit >= left) return "On pace to last until reset";
        return `At this pace the limit hits in ~${duration(toLimit)}`;
    }

    // ---- view ----

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: Theme.tooltipBg
        border.width: 1
        border.color: Theme.tooltipBorder
    }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: AIUsage.cardOpen = false
        Keys.onPressed: event => {
            if (event.key === Qt.Key_R) AIUsage.refresh();
        }
    }

    // Click-away catcher, below the card.
    PanelWindow {
        screen: root.screen
        visible: root.visible
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell-aiusage-scrim"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: AIUsage.cardOpen = false
        }
    }

    component Link: Text {
        id: link
        signal clicked
        property color restColor: root.dim
        color: area.containsMouse ? Theme.foreground : restColor
        font.family: Theme.fontFamily
        font.pixelSize: 11

        MouseArea {
            id: area
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: link.clicked()
        }
    }

    Column {
        id: content
        x: root.pad
        y: root.pad
        width: root.width - 2 * root.pad
        spacing: 14

        Repeater {
            model: AIUsage.entries

            Column {
                id: provider
                required property var modelData
                readonly property var entry: modelData

                width: content.width
                spacing: 10

                // Header: icon, "<Name> Usage", plan.
                Item {
                    width: parent.width
                    height: 26

                    Text {
                        id: glyph
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.iconFor(provider.entry)
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 20
                    }

                    Text {
                        anchors.left: glyph.right
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: `${provider.entry.name} Usage`
                        color: Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 17
                        font.bold: true
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: (provider.entry.stale ? "STALE · " : "") + provider.entry.plan.toUpperCase()
                        color: provider.entry.stale ? Theme.warning : root.dim
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.2
                    }
                }

                Text {
                    visible: provider.entry.error !== ""
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: provider.entry.error
                    color: Theme.warning
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }

                Repeater {
                    model: provider.entry.metrics

                    Column {
                        id: metricRow
                        required property var modelData
                        required property int index
                        readonly property var metric: modelData
                        readonly property bool hasPercent: typeof metric.percent === "number"
                        readonly property real pace: root.elapsed(metric)
                        readonly property string judgement: root.verdict(metric)

                        width: provider.width
                        spacing: 4

                        // Rows rise into place, staggered, each time it opens.
                        opacity: 0
                        transform: Translate { id: rise; y: 6 }

                        Connections {
                            target: root
                            function onVisibleChanged() {
                                if (root.visible) entrance.restart();
                            }
                        }

                        Component.onCompleted: entrance.restart()

                        SequentialAnimation {
                            id: entrance
                            ScriptAction { script: { metricRow.opacity = 0; rise.y = 6; } }
                            PauseAnimation { duration: 60 * metricRow.index }
                            ParallelAnimation {
                                NumberAnimation { target: metricRow; property: "opacity"; to: 1; duration: 220; easing.type: Easing.OutCubic }
                                SpringAnimation { target: rise; property: "y"; to: 0; spring: 3; damping: 0.3 }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 16

                            Text {
                                anchors.left: parent.left
                                text: metricRow.metric.label
                                color: Theme.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }

                            Text {
                                anchors.right: parent.right
                                text: root.resetText(metricRow.metric)
                                color: root.dim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                        }

                        // Bar of percent used, with the even-pace marker.
                        Item {
                            visible: metricRow.hasPercent
                            width: parent.width
                            height: 10

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: root.track

                                Rectangle {
                                    property real shown: 0
                                    width: Math.max(shown > 0 ? height : 0, parent.width * Math.min(100, shown) / 100)
                                    height: parent.height
                                    radius: 3
                                    color: Theme.usageColor(metricRow.metric.percent)

                                    readonly property real reading: metricRow.metric.percent || 0
                                    Component.onCompleted: shown = reading
                                    onReadingChanged: shown = reading
                                    Behavior on shown {
                                        SpringAnimation { spring: 2.5; damping: 0.3; epsilon: 0.2 }
                                    }
                                }
                            }

                            Rectangle {
                                visible: metricRow.pace >= 0
                                x: (parent.width - width) * metricRow.pace
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 12
                                radius: 1.5
                                color: Theme.foreground
                                opacity: 0.8
                            }
                        }

                        Text {
                            text: {
                                const m = metricRow.metric;
                                // Spend metrics carry their own wording ("$0.00 of $28.00").
                                if (m.value && !/^\d+%$/.test(m.value)) return m.value;
                                return `${m.percent}% used`;
                            }
                            color: Theme.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.bold: true
                        }

                        Text {
                            visible: metricRow.judgement !== ""
                            text: metricRow.judgement
                            color: metricRow.judgement.startsWith("At this pace") || metricRow.judgement === "Limit reached"
                                ? Theme.warning : root.dim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        // Footer: last fetch, refresh, full details.
        Item {
            width: content.width
            height: 14

            Text {
                anchors.left: parent.left
                text: AIUsage.loading ? "Refreshing…" : `Updated ${Qt.formatTime(AIUsage.updated, "HH:mm")}`
                color: root.dim
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }

            Row {
                anchors.right: parent.right
                spacing: 16

                Link {
                    text: "↻ refresh"
                    onClicked: AIUsage.refresh()
                }

                Link {
                    text: "details ↗"
                    onClicked: {
                        Quickshell.execDetached(["ghostty", "-e", "ai-usagebar-tui"]);
                        AIUsage.cardOpen = false;
                    }
                }
            }
        }
    }
}
