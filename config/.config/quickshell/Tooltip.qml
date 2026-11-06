import QtQuick
import Quickshell

// Hover tooltip, anchored under the widget that owns it.
// Shows after a short delay so sweeping across the bar stays quiet.
PopupWindow {
    id: root

    property Item anchorItem: null
    property string text: ""
    property bool shown: false

    anchor.item: anchorItem
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 6

    implicitWidth: body.implicitWidth + 20
    implicitHeight: body.implicitHeight + 12
    color: "transparent"
    visible: false

    Timer {
        id: delay
        interval: 420
        onTriggered: root.visible = root.shown && root.text !== ""
    }

    onShownChanged: {
        if (shown) delay.restart();
        else {
            delay.stop();
            visible = false;
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.tooltipBg
        border.width: 1
        border.color: Theme.tooltipBorder

        Text {
            id: body
            anchors.centerIn: parent
            text: root.text
            color: Theme.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
            textFormat: Text.PlainText
        }
    }
}
