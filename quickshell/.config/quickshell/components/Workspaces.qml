import "../"

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Rectangle {
    id: workspacesPill

    // =========================================================
    // Dynamic Glass & Palette (Consistent with Kitty 0.7)
    // =========================================================

    readonly property color bgGlass: Colors.bgGlass !== undefined ? Colors.bgGlass : Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.70)
    readonly property color cardGlass: Colors.cardGlass !== undefined ? Colors.cardGlass : Qt.rgba(Colors.color0.r, Colors.color0.g, Colors.color0.b, 0.40)
    readonly property color borderGlass: Colors.borderGlass !== undefined ? Colors.borderGlass : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.16)
    readonly property color hoverOverlay: Colors.hoverOverlay !== undefined ? Colors.hoverOverlay : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.08)

    // =========================================================
    // Geometry & Slot Configuration
    // =========================================================

    readonly property int leftPadding: 6
    readonly property int rightPadding: 6

    readonly property int slotWidth: 34
    readonly property int itemHeight: 24
    readonly property int spacing: 2

    readonly property int inactiveWidth: 24
    readonly property int activeWidth: 34

    readonly property int geometryDuration: 300

    // =========================================================
    // Workspace Range Calculation
    // =========================================================

    readonly property int maxWorkspaceId: {
        let maxId = 5;

        if (Hyprland.focusedWorkspace) {
            const focusedId = Hyprland.focusedWorkspace.id;
            if (focusedId > 0 && focusedId < 50)
                maxId = Math.max(maxId, focusedId);
        }

        if (Hyprland.workspaces) {
            for (const ws of Hyprland.workspaces.values) {
                if (!ws || ws.id <= 0 || ws.id >= 50)
                    continue;

                const occupied = ws.windows > 0 || (ws.toplevels && ws.toplevels.values.length > 0);
                if (occupied)
                    maxId = Math.max(maxId, ws.id);
            }
        }

        return maxId;
    }

    readonly property int poolSize: Math.max(10, maxWorkspaceId)
    readonly property int activeWorkspaceId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // =========================================================
    // Animated Displayed Workspace Count (Single-Pass Curve)
    // =========================================================

    property real visibleWorkspaceCount: 5

    Behavior on visibleWorkspaceCount {
        NumberAnimation {
            duration: workspacesPill.geometryDuration
            easing.type: Easing.OutCubic
        }
    }

    onMaxWorkspaceIdChanged: {
        visibleWorkspaceCount = maxWorkspaceId;
    }

    Component.onCompleted: {
        visibleWorkspaceCount = maxWorkspaceId;
    }

    // =========================================================
    // Pill Geometry & Glass Container
    // =========================================================

    color: workspacesPill.bgGlass
    radius: 12
    border.color: workspacesPill.borderGlass
    border.width: 1

    height: 32
    implicitHeight: 32

    // Pure mathematical width (Zero lag, zero frame desync)
    width: workspacesPill.leftPadding + workspacesPill.rightPadding + Math.max(1, workspacesPill.visibleWorkspaceCount) * workspacesPill.slotWidth + Math.max(0, workspacesPill.visibleWorkspaceCount - 1) * workspacesPill.spacing

    implicitWidth: width
    Layout.margins: 4

    // Prevents slots from rendering outside the border during expansion
    clip: true

    // =========================================================
    // Wheel Navigation
    // =========================================================

    MouseArea {
        id: wheelArea
        anchors.fill: parent
        acceptedButtons: Qt.NoButton

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                Hyprland.dispatch('hl.dsp.focus({ workspace = "e-1" })');
            } else if (wheel.angleDelta.y < 0) {
                Hyprland.dispatch('hl.dsp.focus({ workspace = "e+1" })');
            }
            wheel.accepted = true;
        }
    }

    // =========================================================
    // Workspace Row (Stationary Fixed Slots)
    // =========================================================

    Row {
        id: workspaceRow

        anchors {
            left: parent.left
            leftMargin: workspacesPill.leftPadding
            verticalCenter: parent.verticalCenter
        }

        spacing: workspacesPill.spacing

        Repeater {
            model: workspacesPill.poolSize

            delegate: Item {
                id: workspaceSlot

                required property int index
                readonly property int workspaceId: index + 1
                readonly property bool inRange: workspaceId <= workspacesPill.maxWorkspaceId

                readonly property var workspace: {
                    if (!Hyprland.workspaces || !inRange)
                        return null;

                    for (const ws of Hyprland.workspaces.values) {
                        if (ws && ws.id === workspaceId)
                            return ws;
                    }
                    return null;
                }

                readonly property bool active: inRange && workspacesPill.activeWorkspaceId === workspaceId
                readonly property bool occupied: inRange && workspace !== null && (workspace.windows > 0 || (workspace.toplevels && workspace.toplevels.values.length > 0))
                readonly property bool hovered: inRange && workspaceMouse.containsMouse

                // Stationary Slot Bounds
                width: workspacesPill.slotWidth
                height: workspacesPill.itemHeight

                opacity: inRange ? 1 : 0
                scale: inRange ? 1 : 0.85

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 240
                        easing.type: Easing.OutCubic
                    }
                }

                // =====================================================
                // Workspace Capsule (Centered in Fixed Slot)
                // =====================================================

                Rectangle {
                    id: workspaceBackground

                    anchors.verticalCenter: parent.verticalCenter
                    x: (workspaceSlot.width - width) / 2

                    width: workspaceSlot.active ? workspacesPill.activeWidth : workspacesPill.inactiveWidth
                    height: workspacesPill.itemHeight
                    radius: 12

                    color: workspaceSlot.active ? Colors.color4 : workspaceSlot.hovered ? workspacesPill.hoverOverlay : "transparent"

                    Behavior on width {
                        NumberAnimation {
                            duration: workspacesPill.geometryDuration
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 140
                            easing.type: Easing.OutQuad
                        }
                    }

                    // Tactile OutBack spring pop
                    scale: workspaceSlot.active ? 1.0 : workspaceSlot.hovered ? 1.04 : 0.96

                    Behavior on scale {
                        NumberAnimation {
                            duration: 240
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.04
                        }
                    }
                }

                // =====================================================
                // Workspace Number Label
                // =====================================================

                Text {
                    anchors.centerIn: parent

                    text: workspaceSlot.workspaceId

                    color: workspaceSlot.active ? Colors.background : workspaceSlot.occupied ? Colors.foreground : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.46)

                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                    font.weight: workspaceSlot.active || workspaceSlot.occupied ? Font.Bold : Font.Medium

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    scale: workspaceSlot.active ? 1.0 : 0.94

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
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

                // =====================================================
                // Interaction
                // =====================================================

                MouseArea {
                    id: workspaceMouse
                    anchors.fill: parent
                    enabled: workspaceSlot.inRange
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        Hyprland.dispatch('hl.dsp.focus({ workspace = "' + workspaceSlot.workspaceId + '" })');
                    }
                }
            }
        }
    }
}
