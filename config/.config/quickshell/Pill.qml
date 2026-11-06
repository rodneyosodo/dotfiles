import QtQuick

// One of the bar's rounded translucent groups. Slots inside run the
// full height of the pill so their hover and click targets line up.
Rectangle {
    id: root

    default property alias content: layout.data
    property alias spacing: layout.spacing

    implicitWidth: layout.implicitWidth + Theme.pillPaddingH * 2
    implicitHeight: Theme.pillHeight

    visible: layout.implicitWidth > 0
    radius: Theme.pillRadius
    color: Theme.pillBg

    Row {
        id: layout
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Theme.pillPaddingH
        spacing: Theme.itemSpacing
    }
}
