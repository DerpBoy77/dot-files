import QtQuick
import "../"

Rectangle {
    id: root

    property bool checked: false
    property bool enabled: true
    signal toggled(bool checked)

    width: 46
    height: 26
    radius: 13
    color: checked ? Colors.color4 : Colors.cardGlass

    Behavior on color {
        ColorAnimation {
            duration: Theme.animHover
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        id: knob
        width: 22
        height: 22
        radius: 11
        color: Colors.background
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 2 : 2

        Behavior on x {
            NumberAnimation {
                duration: Theme.animToggle
                easing.type: Easing.OutExpo
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        enabled: root.enabled
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
        }
    }
}
