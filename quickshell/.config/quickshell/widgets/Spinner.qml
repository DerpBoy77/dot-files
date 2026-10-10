import QtQuick
import QtQuick.Shapes
import "../"

Item {
    id: root

    property real size: 14
    property real lineWidth: 2
    property color color: Colors.color4
    property color trackColor: Colors.borderGlass
    property bool running: true

    implicitWidth: size
    implicitHeight: size

    // Subtle track ring
    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        visible: root.trackColor.a > 0

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.lineWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: Math.max(1, (root.width - root.lineWidth) / 2)
                radiusY: Math.max(1, (root.height - root.lineWidth) / 2)
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    // Rotating active indicator arc
    Item {
        anchors.fill: parent

        Shape {
            anchors.fill: parent
            layer.enabled: true
            layer.samples: 4

            ShapePath {
                strokeColor: root.color
                strokeWidth: root.lineWidth
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap

                PathAngleArc {
                    centerX: root.width / 2
                    centerY: root.height / 2
                    radiusX: Math.max(1, (root.width - root.lineWidth) / 2)
                    radiusY: Math.max(1, (root.height - root.lineWidth) / 2)
                    startAngle: 0
                    sweepAngle: 270
                }
            }
        }

        RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 850
            loops: Animation.Infinite
            running: root.running && root.visible
        }
    }
}
