import "../"

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: workspacesPill

    // =========================================================
    // Dynamic Glass & Palette Helpers (Consistent with Kitty 0.7)
    // =========================================================

    readonly property color bgGlass: Colors.bgGlass !== undefined ? Colors.bgGlass : Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.70)
    readonly property color borderGlass: Colors.borderGlass !== undefined ? Colors.borderGlass : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.16)
    readonly property color hoverOverlay: Colors.hoverOverlay !== undefined ? Colors.hoverOverlay : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.08)

    property int leftPadding: 6
    property int rightPadding: 6

    color: workspacesPill.bgGlass
    radius: 12
    border.color: workspacesPill.borderGlass
    border.width: 1

    implicitHeight: 32
    implicitWidth: wsRow.implicitWidth + leftPadding + rightPadding

    Layout.margins: 4

    // Mouse wheel cycling across workspaces (Hyprland Lua syntax)
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                Hyprland.dispatch('hl.dsp.focus({ workspace = "e-1" })');
            } else {
                Hyprland.dispatch('hl.dsp.focus({ workspace = "e+1" })');
            }
        }
    }

    Row {
        id: wsRow

        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: 5

            delegate: Rectangle {
                id: wsItem

                required property int index

                readonly property var workspace: {
                    if (!Hyprland.workspaces)
                        return null;
                    return Hyprland.workspaces.values.find(ws => ws.id === index + 1) || null;
                }

                readonly property bool active: Hyprland.focusedWorkspace !== null && Hyprland.focusedWorkspace.id === index + 1
                readonly property bool occupied: workspace !== null && (workspace.windows > 0 || (workspace.toplevels && workspace.toplevels.values.length > 0))
                readonly property bool hovered: wsMa.containsMouse

                width: active ? 38 : 24
                height: 24
                radius: 12

                color: active ? Colors.color4 : hovered ? workspacesPill.hoverOverlay : "transparent"

                Behavior on width {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 140
                        easing.type: Easing.OutQuad
                    }
                }

                Text {
                    id: workspaceText

                    anchors.centerIn: parent

                    text: (wsItem.index + 1).toString()

                    color: wsItem.active ? Colors.background : wsItem.occupied ? Colors.foreground : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.38)

                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    font.weight: wsItem.active || wsItem.occupied ? Font.Bold : Font.Medium

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    scale: wsItem.active ? 1.0 : wsItem.hovered ? 1.05 : 0.95

                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                            easing.type: Easing.OutQuad
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                MouseArea {
                    id: wsMa

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        Hyprland.dispatch('hl.dsp.focus({ workspace = "' + (wsItem.index + 1) + '" })');
                    }
                }
            }
        }
    }
}
