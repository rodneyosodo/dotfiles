import QtQuick
import QtQuick.Shapes

// A thin progress ring: a full track with an arc from 12 o'clock showing
// percent used. The arc settles with a light spring overshoot when the
// reading changes, as in CodeNotch / omarchy-ai-usage.
Item {
    id: ring

    property real percent: 0
    property color color: Theme.foreground
    property color trackColor: Qt.rgba(Theme.foreground.r, Theme.foreground.g, Theme.foreground.b, 0.15)
    property real thickness: 2.5

    implicitWidth: 22
    implicitHeight: 22

    property real shown: 0
    Component.onCompleted: shown = percent
    onPercentChanged: shown = percent

    Behavior on shown {
        SpringAnimation { spring: 2.5; damping: 0.28; epsilon: 0.2 }
    }

    readonly property real radius: (Math.min(width, height) - thickness) / 2
    readonly property real sweep: 360 * Math.max(0, Math.min(100, shown)) / 100

    // Antialiasing for the curves.
    layer.enabled: true
    layer.samples: 4

    Shape {
        anchors.fill: parent

        ShapePath {
            fillColor: "transparent"
            strokeColor: ring.trackColor
            strokeWidth: ring.thickness

            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: 0
                sweepAngle: 360
            }
        }

        ShapePath {
            fillColor: "transparent"
            strokeColor: ring.sweep > 1 ? ring.color : "transparent"
            strokeWidth: ring.thickness
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: ring.width / 2
                centerY: ring.height / 2
                radiusX: ring.radius
                radiusY: ring.radius
                startAngle: -90
                sweepAngle: ring.sweep
            }
        }
    }
}
