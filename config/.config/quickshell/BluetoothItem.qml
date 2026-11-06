import Quickshell.Io
import Quickshell.Bluetooth

// left = toggle adapter · right = blueman
Widget {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: adapter ? adapter.enabled : false

    readonly property var connectedDevices: {
        const out = [];
        for (const dev of Bluetooth.devices.values) {
            if (dev.connected) out.push(dev);
        }
        return out;
    }

    text: {
        if (!adapter || !enabled) return Theme.iconBluetoothOff;
        return connectedDevices.length > 0 ? Theme.iconBluetoothConnected : Theme.iconBluetoothOn;
    }

    dimmed: !enabled
    tooltip: {
        if (!adapter) return "No Bluetooth adapter";
        if (!enabled) return "Bluetooth off\nClick to enable";
        if (connectedDevices.length === 0) return "Bluetooth on — nothing connected\nRight click for manager";
        const names = connectedDevices.map(d => {
            return d.batteryAvailable
                ? `${d.name} (${Math.round(d.battery * 100)}%)`
                : d.name;
        });
        return `Connected:\n${names.join("\n")}`;
    }

    onActivated: button => {
        if (button === Qt.RightButton) manager.running = true;
        else if (root.adapter) root.adapter.enabled = !root.adapter.enabled;
    }

    Process {
        id: manager
        command: ["blueman-manager"]
    }
}
