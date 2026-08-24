//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark
import "./components"

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    implicitHeight: 48

    color: "transparent"

    exclusiveZone: 32

    margins {
        top: 0
        left: 12
        right: 12
        bottom: 0
    }

    anchors {
        top: true
        left: true
        right: true
    }

    Workspaces {
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
        }
    }

    Clock {
        id: clock

        barWindow: root

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }
    }

    SystemPill {
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
    }
}
