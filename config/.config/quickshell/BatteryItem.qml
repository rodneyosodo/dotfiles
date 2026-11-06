import Quickshell.Services.UPower

// Quickshell reports UPower percentages as a 0-1 fraction, not 0-100.
Widget {
    id: root

    readonly property var battery: UPower.displayDevice
    readonly property bool present: battery && battery.isLaptopBattery && battery.isPresent
    readonly property int percent: present ? Math.round(battery.percentage * 100) : 0
    readonly property bool charging: present
        && (battery.state === UPowerDeviceState.Charging
            || battery.state === UPowerDeviceState.PendingCharge)
    readonly property bool full: present && battery.state === UPowerDeviceState.FullyCharged

    function humanTime(seconds) {
        if (!seconds || seconds <= 0) return "";
        const h = Math.floor(seconds / 3600);
        const m = Math.round((seconds % 3600) / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }

    text: {
        if (!present) return "";
        if (charging) return Theme.iconCharging;
        const icons = Theme.iconsBattery;
        const i = Math.min(icons.length - 1, Math.floor(percent / 100 * icons.length));
        return icons[Math.max(0, i)];
    }

    visible: present
    dimmed: full && !charging

    color: {
        if (charging || full) return Theme.foreground;
        if (percent <= 20) return Theme.urgent;
        if (percent <= 30) return Theme.warning;
        return Theme.foreground;
    }

    tooltip: {
        if (!present) return "";
        let s = `Battery ${percent}%`;
        if (charging) {
            const t = humanTime(battery.timeToFull);
            s += t ? `\nCharging — ${t} to full` : "\nCharging";
        } else if (full) {
            s += "\nFully charged";
        } else {
            const t = humanTime(battery.timeToEmpty);
            if (t) s += `\n${t} remaining`;
        }
        return s;
    }
}
