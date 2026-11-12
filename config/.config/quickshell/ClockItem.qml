import Quickshell
import Quickshell.Hyprland

// System timezone is Africa/Nairobi, so local time matches the old waybar config.
// Left click opens the calendar and time zones; right click cycles through the
// label formats, as Omarchy's clock does.
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
    tooltip: ClockState.open ? "" : Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
        + "\nClick for calendar and time zones · right click to change format"

    onActivated: button => {
        if (button === Qt.RightButton)
            root.formatIndex = (root.formatIndex + 1) % root.formats.length;
        else
            ClockState.toggle();
    }

    // One bar per monitor: only the one on the focused monitor shows it.
    ClockPopup {
        screen: root.QsWindow.window ? root.QsWindow.window.screen : null
        visible: ClockState.open
            && Hyprland.focusedMonitor !== null
            && root.QsWindow.window !== null
            && Hyprland.focusedMonitor.name === root.QsWindow.window.screen.name
    }
}
