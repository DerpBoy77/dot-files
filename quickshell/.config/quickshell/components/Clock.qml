import "../"

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: clock

    // Passed from the PanelWindow.
    property var barWindow

    property bool expanded: false
    property bool popupShown: false
    property date currentTime: new Date()

    // Dynamic Glass & Palette Fallbacks
    readonly property color bgGlass: Colors.bgGlass !== undefined ? Colors.bgGlass : Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.70)
    readonly property color borderGlass: Colors.borderGlass !== undefined ? Colors.borderGlass : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.16)
    readonly property color hoverOverlay: Colors.hoverOverlay !== undefined ? Colors.hoverOverlay : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.08)

    readonly property int closedWidth: timeText.implicitWidth + 32
    readonly property int closedHeight: 32

    readonly property int expandedWidth: 220
    readonly property int expandedHeight: 112

    implicitWidth: closedWidth
    implicitHeight: closedHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            clock.currentTime = new Date();
        }
    }

    // Dismiss with Escape key
    Shortcut {
        sequence: "Escape"
        enabled: clock.expanded
        onActivated: clock.close()
    }

    // =========================================================
    // NORMAL CLOCK PILL
    // =========================================================

    Rectangle {
        id: closedPill

        anchors.fill: parent

        visible: !clock.expanded
        opacity: clock.expanded ? 0 : 1

        color: clock.bgGlass
        radius: 12

        border.color: clock.borderGlass
        border.width: 1

        Behavior on opacity {
            NumberAnimation {
                duration: 90
                easing.type: Easing.OutQuad
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius

            color: clockMouse.containsMouse ? clock.hoverOverlay : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }
        }

        Text {
            id: timeText

            anchors.centerIn: parent

            text: Qt.formatDateTime(clock.currentTime, "HH:mm:ss")

            color: Colors.foreground

            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 13
            font.weight: Font.Bold

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
            id: clockMouse

            anchors.fill: parent

            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                clock.open();
            }
        }
    }

    // =========================================================
    // DYNAMIC ISLAND POPUP
    // =========================================================

    PopupWindow {
        id: popup

        visible: clock.popupShown

        implicitWidth: clock.expandedWidth
        implicitHeight: clock.expandedHeight

        color: "transparent"
        grabFocus: false

        anchor {
            window: clock.barWindow

            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right

            rect.x: (clock.barWindow !== null ? (clock.barWindow.width - clock.expandedWidth) / 2 : 0)
            rect.y: 8
        }

        // =====================================================
        // MORPHING PILL
        // =====================================================

        Rectangle {
            id: island

            x: (parent.width - width) / 2
            y: 0

            width: clock.expanded ? clock.expandedWidth : clock.closedWidth
            height: clock.expanded ? clock.expandedHeight : clock.closedHeight
            radius: clock.expanded ? 18 : 12

            color: clock.bgGlass
            border.color: clock.borderGlass
            border.width: 1

            clip: true

            focus: true

            Keys.onEscapePressed: {
                clock.close();
            }

            Behavior on width {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 340
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on radius {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }

            // =================================================
            // CLOCK
            // =================================================

            Text {
                id: popupTime

                anchors.horizontalCenter: parent.horizontalCenter

                y: clock.expanded ? 10 : 0

                width: parent.width
                height: clock.closedHeight

                text: Qt.formatDateTime(clock.currentTime, "HH:mm:ss")

                color: Colors.foreground

                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 13
                font.weight: Font.Bold

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                Behavior on y {
                    NumberAnimation {
                        duration: 280
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // =================================================
            // DIVIDER
            // =================================================

            Rectangle {
                id: divider

                anchors.horizontalCenter: parent.horizontalCenter

                y: 41

                width: clock.expanded ? parent.width - 32 : 0
                height: 1

                color: clock.borderGlass

                opacity: clock.expanded ? 1 : 0

                Behavior on width {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutQuad
                    }
                }
            }

            // =================================================
            // DATE CONTENT
            // =================================================

            Column {
                id: dateContent

                anchors.horizontalCenter: parent.horizontalCenter

                y: 50

                width: parent.width - 24
                spacing: 3

                opacity: clock.expanded ? 1 : 0
                scale: clock.expanded ? 1 : 0.88

                Text {
                    width: parent.width
                    text: Qt.formatDateTime(clock.currentTime, "dddd")
                    color: Colors.color4

                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 18
                    font.weight: Font.Bold

                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    width: parent.width
                    text: Qt.formatDateTime(clock.currentTime, "MMMM d, yyyy")
                    color: Colors.foreground

                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 13

                    horizontalAlignment: Text.AlignHCenter
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.05
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    clock.close();
                }
            }
        }

        onVisibleChanged: {
            if (!visible && clock.popupShown)
                clock.popupShown = false;
        }
    }

    // =========================================================
    // OUTSIDE CLICK DISMISSAL
    // =========================================================

    HyprlandFocusGrab {
        id: focusGrab
        windows: [popup]
        active: clock.expanded

        onCleared: {
            if (clock.expanded)
                clock.close();
        }
    }

    // =========================================================
    // OPEN / CLOSE CONTROLLERS
    // =========================================================

    function open() {
        if (clock.expanded)
            return;
        closeTimer.stop();

        clock.popupShown = true;
        clock.expanded = false;

        Qt.callLater(function () {
            if (!clock.popupShown)
                return;
            popup.anchor.updateAnchor();

            Qt.callLater(function () {
                if (clock.popupShown)
                    clock.expanded = true;
            });
        });
    }

    function close() {
        if (!clock.popupShown)
            return;
        clock.expanded = false;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 350
        repeat: false

        onTriggered: {
            clock.popupShown = false;
        }
    }
}
