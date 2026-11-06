import Quickshell

// System timezone is Africa/Nairobi, so local time matches the old waybar config.
// Right click cycles through the label formats, as Omarchy's clock does.
Widget {
    id: root

    readonly property var formats: [
        "ddd dd.MM.yy  HH:mm:ss",
        "ddd dd.MM.yy  HH:mm",
        "HH:mm"
    ]
    property int formatIndex: 0

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    text: Qt.formatDateTime(clock.date, formats[formatIndex])
    iconSlot: false
    tooltip: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy") + "\nRight click to change format"

    onActivated: button => {
        if (button === Qt.RightButton)
            root.formatIndex = (root.formatIndex + 1) % root.formats.length;
    }
}
