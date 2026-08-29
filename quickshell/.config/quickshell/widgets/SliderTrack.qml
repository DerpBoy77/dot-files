import QtQuick
import "../"

Item {
    id: root

    property real value: 0.0
    property bool muted: false
    property bool enabled: true

    property color fillColor: muted ? Colors.color8 : Colors.color4
    property color trackColor: Colors.cardGlass
    property int trackHeight: 10
    property int thumbSize: 18

    signal moved(real value)

    width: parent ? parent.width : 200
    height: 32
    implicitHeight: 32

    Rectangle {
        id: track
        x: 6
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(1, parent.width - 12)
        height: root.trackHeight
        radius: root.trackHeight / 2
        color: root.trackColor

        Rectangle {
            id: fill
            width: Math.max(0, Math.min(track.width, track.width * Math.max(0, Math.min(1.0, root.value))))
            height: track.height
            radius: track.radius
            color: root.fillColor

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animHover
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on width {
                enabled: !sliderMouse.pressed
                NumberAnimation {
                    duration: Theme.animHover
                    easing.type: Easing.OutQuad
                }
            }
        }

        Rectangle {
            id: thumb
            width: root.thumbSize
            height: root.thumbSize
            radius: root.thumbSize / 2
            color: Colors.foreground
            border.color: Colors.background
            border.width: 2
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(track.width - width, (track.width * Math.max(0, Math.min(1.0, root.value))) - width / 2))

            Behavior on x {
                enabled: !sliderMouse.pressed
                NumberAnimation {
                    duration: Theme.animHover
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    MouseArea {
        id: sliderMouse
        anchors.fill: parent
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.enabled
        preventStealing: true

        function updateFromMouse(mouseX) {
            let availableWidth = Math.max(1, track.width);
            let val = Math.max(0, Math.min(1.0, (mouseX - track.x) / availableWidth));
            root.moved(val);
        }

        onClicked: mouse => updateFromMouse(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                updateFromMouse(mouse.x);
        }
        onWheel: wheel => {
            let step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
            let val = Math.max(0, Math.min(1.0, root.value + step));
            root.moved(val);
        }
    }
}
