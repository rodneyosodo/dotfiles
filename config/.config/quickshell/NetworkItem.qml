import Quickshell.Io
import Quickshell.Networking

Widget {
    id: root

    readonly property var devices: Networking.devices.values

    readonly property var activeDevice: {
        for (const dev of devices) {
            if (dev.connected) return dev;
        }
        return null;
    }

    readonly property var activeNetwork: {
        if (!activeDevice) return null;
        for (const net of activeDevice.networks.values) {
            if (net.connected) return net;
        }
        return null;
    }

    readonly property bool wired: activeDevice && activeDevice.type === DeviceType.Wired

    // Quickshell reports signal strength as a 0-1 fraction, not 0-100.
    readonly property int signal: activeNetwork ? Math.round(activeNetwork.signalStrength * 100) : 0

    text: {
        if (!activeDevice) return Theme.iconWifiOff;
        if (wired) return Theme.iconWired;
        const s = signal;
        if (s >= 75) return Theme.iconsWifi[3];
        if (s >= 50) return Theme.iconsWifi[2];
        if (s >= 25) return Theme.iconsWifi[1];
        return Theme.iconsWifi[0];
    }

    color: activeDevice ? Theme.foreground : Theme.urgent
    dimmed: !activeDevice

    tooltip: {
        if (!activeDevice) return "Disconnected";
        if (wired) return `Wired — ${activeDevice.name}\n${activeDevice.address}`;
        const name = activeNetwork ? activeNetwork.name : "Wi-Fi";
        const sig = activeNetwork ? `${signal}%` : "";
        return `${name}  ${sig}\n${activeDevice.address}\nClick for nmtui`;
    }

    onActivated: netProc.running = true

    Process {
        id: netProc
        command: ["ghostty", "-e", "nmtui"]
    }
}
