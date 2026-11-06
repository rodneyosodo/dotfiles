pragma Singleton

import QtQuick
import Quickshell

// Design tokens. Following Omarchy's bar, the palette is deliberately
// restrained: one foreground colour for everything, with the accent and
// urgent colours reserved for state that actually needs attention.
// State is otherwise shown through opacity, not hue.
Singleton {
    // ---- palette (Catppuccin Mocha) ----
    readonly property color base: "#1e1e2e"
    readonly property color foreground: "#cdd6f4"
    readonly property color accent: "#cba6f7"
    readonly property color urgent: "#f38ba8"
    readonly property color warning: "#fab387"
    readonly property color good: "#a6e3a1"

    readonly property color pillBg: Qt.rgba(base.r, base.g, base.b, 0.72)
    readonly property color tooltipBg: Qt.rgba(base.r, base.g, base.b, 0.96)
    readonly property color tooltipBorder: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.12)

    // ---- state opacity ----
    readonly property real opacityIdle: 1.0
    readonly property real opacityDim: 0.45
    readonly property real opacityPressed: 0.6

    // ---- typography ----
    readonly property string fontFamily: "CodeNewRoman Nerd Font Propo"
    readonly property int fontSize: 13

    // ---- geometry ----
    readonly property int barHeight: 40
    readonly property int pillHeight: 30
    readonly property int pillRadius: 10
    readonly property int pillPaddingH: 10
    readonly property int itemSpacing: 4

    // Uniform slot widths keep the bar from shifting as labels change.
    readonly property int iconSlot: 26
    readonly property int labelPadding: 8

    readonly property int sideMargin: 10
    readonly property int animDuration: 180

    // ---- icons ----
    // Material Design glyphs from the Nerd Font, written as codepoints rather
    // than literal characters: the literals are invisible in an editor without
    // the font, and are easily dropped when the file is copied around.
    function icon(codepoint) {
        return String.fromCodePoint(codepoint);
    }

    readonly property string iconArch: icon(0xF08C7)
    readonly property string iconBell: icon(0xF009A)
    readonly property string iconCpu: icon(0xF061A)
    readonly property string iconMemory: icon(0xF035B)
    readonly property string iconDisk: icon(0xF02CA)
    readonly property string iconThermometer: icon(0xF050F)
    readonly property string iconPower: "⏻"

    readonly property string iconWorkspaceActive: icon(0xF14FB)

    readonly property var iconsVolume: [icon(0xF057F), icon(0xF0580), icon(0xF057E)]
    readonly property string iconVolumeMuted: icon(0xF0581)

    readonly property string iconBluetoothOff: icon(0xF00B2)
    readonly property string iconBluetoothOn: icon(0xF00AF)
    readonly property string iconBluetoothConnected: icon(0xF00B1)

    readonly property string iconWired: icon(0xF0200)
    readonly property string iconWifiOff: icon(0xF092D)
    readonly property var iconsWifi: [icon(0xF091F), icon(0xF0922), icon(0xF0925), icon(0xF0928)]

    readonly property string iconCharging: icon(0xF0084)
    readonly property var iconsBattery: [
        icon(0xF007A), icon(0xF007B), icon(0xF007D),
        icon(0xF007F), icon(0xF0081), icon(0xF0082), icon(0xF0079)
    ]
}
