import QtQuick
import Quickshell

// A single slot on the bar: a label with hover, press, wheel and tooltip
// handling. Modelled on Omarchy's WidgetButton — icon glyphs get a fixed
// slot width so the bar doesn't shift as values change, and state is shown
// through opacity rather than colour.
Item {
    id: root

    property string text: ""
    property color color: Theme.foreground
    property string tooltip: ""
    property bool dimmed: false
    property bool interactive: true
    // Icon glyphs sit in a uniform slot; text labels size to their content.
    property bool iconSlot: isIconGlyph(text)
    // Caps a long label (a window title, say); -1 leaves it unbounded.
    property int maxWidth: -1

    signal activated(int button)
    signal wheel(int delta)

    function isIconGlyph(value) {
        const s = String(value || "");
        if (!s) return false;
        const code = s.codePointAt(0);
        if (s.length !== (code > 0xffff ? 2 : 1)) return false;
        return (code >= 0xe000 && code <= 0xf8ff)
            || (code >= 0xf0000 && code <= 0xffffd)
            || (code >= 0x100000 && code <= 0x10fffd);
    }

    visible: text !== ""
    implicitWidth: {
        if (iconSlot) return Theme.iconSlot;
        const natural = Math.max(Theme.iconSlot, label.implicitWidth + Theme.labelPadding * 2);
        return maxWidth > 0 ? Math.min(maxWidth, natural) : natural;
    }
    implicitHeight: Theme.pillHeight

    opacity: dimmed ? Theme.opacityDim : (mouse.pressed ? Theme.opacityPressed : Theme.opacityIdle)

    Behavior on opacity {
        NumberAnimation { duration: Theme.animDuration; easing.type: Easing.OutCubic }
    }

    Text {
        id: label
        anchors.centerIn: parent
        width: root.maxWidth > 0 ? Math.min(root.maxWidth - Theme.labelPadding * 2, implicitWidth) : implicitWidth
        elide: root.maxWidth > 0 ? Text.ElideRight : Text.ElideNone
        horizontalAlignment: Text.AlignHCenter
        text: root.text
        color: mouse.containsMouse && root.interactive
            ? Qt.lighter(root.color, 1.25)
            : root.color
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.bold: true
        textFormat: Text.PlainText

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => root.activated(event.button)
        onWheel: event => {
            root.wheel(event.angleDelta.y);
            event.accepted = true;
        }
    }

    Tooltip {
        anchorItem: root
        text: root.tooltip
        shown: mouse.containsMouse && root.tooltip !== "" && !mouse.pressed
    }
}
