import QtQuick
import Quickshell
import Quickshell.Hyprland

// One slot per AI plan: the provider's icon inside a usage ring, then the
// percent used of whichever limit window is closest to running out. The ring
// follows the quota colour scale (green, yellow, orange, red).
// left = usage card · right = refresh
Row {
    id: root

    spacing: Theme.itemSpacing
    visible: AIUsage.available && AIUsage.entries.length > 0

    readonly property var icons: ({
        "anthropic": Theme.iconClaude,
        "opencode-go": Theme.iconOpenCode
    })

    function iconFor(entry) {
        return icons[entry.id] || entry.name.slice(0, 1);
    }

    Repeater {
        model: AIUsage.entries

        Item {
            id: slot
            required property var modelData
            readonly property var entry: modelData
            readonly property int percent: entry.percent
            readonly property bool failed: entry.error !== "" && percent < 0

            implicitWidth: content.implicitWidth + Theme.labelPadding * 2
            implicitHeight: Theme.pillHeight
            opacity: mouse.pressed ? Theme.opacityPressed : Theme.opacityIdle

            Row {
                id: content
                anchors.centerIn: parent
                spacing: 6

                UsageRing {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    percent: Math.max(0, slot.percent)
                    color: Theme.usageColor(slot.percent)

                    Text {
                        anchors.centerIn: parent
                        text: root.iconFor(slot.entry)
                        color: slot.failed ? Theme.warning : Theme.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: slot.failed ? "!" : (slot.percent < 0 ? "–" : `${slot.percent}%`)
                    color: {
                        if (slot.failed) return Theme.warning;
                        const c = mouse.containsMouse ? Qt.lighter(Theme.foreground, 1.25) : Theme.foreground;
                        return c;
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: event => {
                    if (event.button === Qt.RightButton) {
                        AIUsage.refresh();
                        return;
                    }
                    AIUsage.toggleCard();
                }
            }

            Tooltip {
                anchorItem: slot
                text: `${slot.entry.name}${slot.entry.plan ? " · " + slot.entry.plan : ""}\nClick for usage · right click to refresh`
                shown: mouse.containsMouse && !mouse.pressed && !AIUsage.cardOpen
            }
        }
    }

    // One bar per monitor: only the one on the focused monitor shows it.
    AIUsageCard {
        id: card
        screen: root.QsWindow.window ? root.QsWindow.window.screen : null
        visible: AIUsage.cardOpen
            && Hyprland.focusedMonitor !== null
            && root.QsWindow.window !== null
            && Hyprland.focusedMonitor.name === root.QsWindow.window.screen.name
        iconFor: root.iconFor
        // Line up under the AI slots, however it was opened.
        onVisibleChanged: if (visible) anchorRight = root.mapToItem(null, root.width, 0).x
    }
}
