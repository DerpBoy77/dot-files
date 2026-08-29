import QtQuick
import "../"

Rectangle {
    id: root

    property bool hoverable: false
    property alias containsMouse: mouseArea.containsMouse
    property alias mouseArea: mouseArea

    color: Colors.bgGlass
    radius: Theme.pillRadius
    border.color: Colors.borderGlass
    border.width: 1
    clip: true

    Rectangle {
        id: hoverOverlay
        anchors.fill: parent
        radius: parent.radius
        visible: root.hoverable
        color: mouseArea.pressed ? Colors.pressedOverlay : mouseArea.containsMouse ? Colors.hoverOverlay : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Theme.animHover
                easing.type: Easing.OutQuad
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: root.hoverable
        enabled: root.hoverable
        cursorShape: root.hoverable ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
