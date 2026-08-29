import QtQuick
import "../"

Rectangle {
    id: root

    property string iconText: ""
    property int iconPixelSize: Theme.fontSizeBody
    property color iconColor: Colors.foreground
    property color iconHoverColor: Colors.color4
    property color bgColor: "transparent"
    property color bgHoverColor: Colors.hoverOverlay
    property color bgPressedColor: Colors.pressedOverlay

    property alias mouseArea: buttonMouse

    signal clicked()

    width: 24
    height: 24
    radius: Theme.smallRadius
    color: buttonMouse.pressed ? root.bgPressedColor : buttonMouse.containsMouse ? root.bgHoverColor : root.bgColor

    Behavior on color {
        ColorAnimation {
            duration: Theme.animHover
            easing.type: Easing.OutQuad
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.iconText
        color: buttonMouse.containsMouse ? root.iconHoverColor : root.iconColor
        font.family: Theme.fontFamily
        font.pixelSize: root.iconPixelSize

        Behavior on color {
            ColorAnimation {
                duration: Theme.animHover
                easing.type: Easing.OutQuad
            }
        }
    }

    MouseArea {
        id: buttonMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
