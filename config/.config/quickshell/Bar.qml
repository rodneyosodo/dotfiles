import QtQuick
import Quickshell
import Quickshell.Io

// Top bar: three translucent pills carrying the old waybar module layout,
// with Omarchy's restraint inside them — one foreground colour, uniform
// slots, state shown through opacity, tooltips and scroll on hover.
PanelWindow {
    id: bar

    required property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: Theme.barHeight
    color: "transparent"

    // ---- left: launcher, notifications, workspaces, window title ----
    Pill {
        anchors {
            left: parent.left
            leftMargin: Theme.sideMargin
            verticalCenter: parent.verticalCenter
        }

        Widget {
            text: Theme.iconArch
            color: Theme.accent
            tooltip: "Applications\nRight click for a terminal"
            onActivated: button => button === Qt.RightButton
                ? terminalProc.running = true
                : menuProc.running = true
        }

        Widget {
            text: Theme.iconBell
            tooltip: "Notifications\nRight click for Do not disturb"
            onActivated: button => button === Qt.RightButton
                ? dndProc.running = true
                : notifyProc.running = true
        }

        Workspaces {}

        ActiveWindow {}
    }

    // ---- center: clock ----
    Pill {
        anchors.centerIn: parent

        ClockItem {}
    }

    // ---- right: system stats, audio, bluetooth, network, battery, power ----
    Pill {
        anchors {
            right: parent.right
            rightMargin: Theme.sideMargin
            verticalCenter: parent.verticalCenter
        }

        Widget {
            text: `${Theme.iconCpu} ${SysInfo.cpuPercent}%`
            iconSlot: false
            dimmed: SysInfo.cpuPercent < 50
            color: SysInfo.cpuPercent >= 85 ? Theme.urgent : Theme.foreground
            tooltip: `CPU ${SysInfo.cpuPercent}%\nTemperature ${SysInfo.tempC}°C`
            onActivated: monitorProc.running = true
        }

        Widget {
            text: `${Theme.iconMemory} ${SysInfo.memPercent}%`
            iconSlot: false
            dimmed: SysInfo.memPercent < 50
            color: SysInfo.memPercent >= 90 ? Theme.urgent : Theme.foreground
            tooltip: `Memory ${SysInfo.memPercent}%\n`
                + `${SysInfo.memUsedGiB.toFixed(1)} of ${SysInfo.memTotalGiB.toFixed(1)} GiB used`
            onActivated: monitorProc.running = true
        }

        Widget {
            text: `${Theme.iconDisk} ${SysInfo.diskPercent}%`
            iconSlot: false
            dimmed: SysInfo.diskPercent < 80
            color: SysInfo.diskPercent >= 90 ? Theme.urgent : Theme.foreground
            tooltip: `Root filesystem ${SysInfo.diskPercent}%\n`
                + `${SysInfo.diskUsed} of ${SysInfo.diskTotal} used`
            onActivated: monitorProc.running = true
        }

        VolumeItem {}
        BluetoothItem {}
        NetworkItem {}
        BatteryItem {}

        Widget {
            text: Theme.iconPower
            color: Theme.urgent
            tooltip: "Session"
            onActivated: powerProc.running = true
        }
    }

    Process {
        id: menuProc
        command: ["wofi", "--show", "drun"]
    }

    Process {
        id: terminalProc
        command: ["ghostty"]
    }

    Process {
        id: notifyProc
        command: ["hokum"]
    }

    Process {
        id: dndProc
        command: ["hokum", "dnd", "toggle"]
    }

    Process {
        id: monitorProc
        command: ["ghostty", "-e", "btop"]
    }

    Process {
        id: powerProc
        command: ["wlogout"]
    }
}
