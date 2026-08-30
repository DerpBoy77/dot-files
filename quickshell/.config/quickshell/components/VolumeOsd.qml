import "../"
import "../services"

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: osdWindow
    required property var screen

    // Overlay layer draws above fullscreen games and videos
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "volume-osd"

    color: "transparent"
    exclusiveZone: -1 // Ignore top bar exclusive zone to attach at physical top

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: 0
        left: 0
        right: 0
        bottom: 0
    }

    implicitHeight: 90
    visible: false

    // =========================================================
    // Fullscreen Detection (Hyprland)
    // =========================================================

    readonly property bool isFullscreen: {
        if (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.hasFullscreen)
            return true;

        if (!Hyprland.workspaces)
            return false;

        for (let ws of Hyprland.workspaces.values) {
            if (ws && ws.active && ws.hasFullscreen) {
                if (!ws.monitor || !osdWindow.screen || ws.monitor.name === osdWindow.screen.name) {
                    return true;
                }
            }
        }
        return false;
    }

    // Connect to AudioService trigger
    Connections {
        target: AudioService

        function onVolumeChanged() {
            // Only trigger if a fullscreen application is active
            if (!osdWindow.isFullscreen)
                return;

            osdWindow.visible = true;
            osdCard.state = "visible";
            hideTimer.restart();
        }
    }

    // Auto-dismiss timer (1.6s)
    Timer {
        id: hideTimer
        interval: 1600
        repeat: false
        onTriggered: {
            osdCard.state = "hidden";
        }
    }

    // =========================================================
    // OSD Card (Morphing Circle -> Pill)
    // =========================================================

    Rectangle {
        id: osdCard
        anchors.horizontalCenter: parent.horizontalCenter

        height: 46
        radius: height / 2

        // Increased opacity (90% background glass)
        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.90)
        border.color: AudioService.outputMuted ? Colors.color1 : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.22)
        border.width: 1
        clip: true

        // State Machine for Chained Motion
        state: "hidden"

        states: [
            State {
                name: "hidden"
                PropertyChanges {
                    target: osdCard
                    y: -osdCard.height
                    width: 46 // Circle (46x46)
                }
                PropertyChanges {
                    target: expandingContent
                    opacity: 0
                }
            },
            State {
                name: "visible"
                PropertyChanges {
                    target: osdCard
                    y: 16
                    width: 260 // Full pill capsule
                }
                PropertyChanges {
                    target: expandingContent
                    opacity: 1
                }
            }
        ]

        transitions: [
            // Entrance: 1. Drop Circle from Bezel -> 2. Expand into Pill
            Transition {
                from: "hidden"
                to: "visible"
                SequentialAnimation {
                    // Step 1: Drop circle from top edge
                    NumberAnimation {
                        target: osdCard
                        property: "y"
                        from: -osdCard.height
                        to: 16
                        duration: 220
                        easing.type: Easing.OutCubic
                    }

                    // Step 2: Smoothly expand width & reveal stationary slider
                    ParallelAnimation {
                        NumberAnimation {
                            target: osdCard
                            property: "width"
                            from: 46
                            to: 260
                            duration: 260
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.10
                        }
                        NumberAnimation {
                            target: expandingContent
                            property: "opacity"
                            from: 0.0
                            to: 1.0
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            },

            // Exit: 1. Collapse Pill into Circle -> 2. Retract into Bezel
            Transition {
                from: "visible"
                to: "hidden"
                SequentialAnimation {
                    // Step 1: Fade out slider & collapse width back to circle
                    ParallelAnimation {
                        NumberAnimation {
                            target: expandingContent
                            property: "opacity"
                            to: 0.0
                            duration: 120
                            easing.type: Easing.OutQuad
                        }
                        NumberAnimation {
                            target: osdCard
                            property: "width"
                            to: 46
                            duration: 180
                            easing.type: Easing.InCubic
                        }
                    }

                    // Step 2: Slide circle straight up into top monitor bezel
                    NumberAnimation {
                        target: osdCard
                        property: "y"
                        from: 16
                        to: -osdCard.height
                        duration: 180
                        easing.type: Easing.InCubic
                    }

                    // Step 3: Unmount surface when fully off-screen
                    ScriptAction {
                        script: {
                            if (osdCard.state === "hidden")
                                osdWindow.visible = false;
                        }
                    }
                }
            }
        ]

        // Stationary Audio Icon (Centered in initial 46px circle, pinned to left in pill)
        Text {
            id: volumeIcon
            anchors {
                left: parent.left
                leftMargin: 14
                verticalCenter: parent.verticalCenter
            }
            width: 18
            text: AudioService.outputIcon
            color: AudioService.outputMuted ? Colors.color1 : Colors.color4
            font.family: "JetBrainsMono Nerd Font Propo"
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        // Fixed-width viewport container (prevents slider resizing stutter during morph)
        RowLayout {
            id: expandingContent
            anchors {
                left: volumeIcon.right
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            width: 202 // 260 total - 14 - 18 - 10 - 16 right margin
            spacing: 12

            // Inset Progress Track
            Rectangle {
                id: volumeTrack
                Layout.fillWidth: true
                height: 6
                radius: 3
                color: Qt.rgba(Colors.color0.r, Colors.color0.g, Colors.color0.b, 0.55)
                border.color: Colors.borderGlass
                border.width: 1
                clip: true

                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    width: parent.width * AudioService.outputVolume
                    radius: 3
                    color: AudioService.outputMuted ? Colors.color8 : Colors.color4

                    // Only animates when AudioService volume changes, never during card expansion
                    Behavior on width {
                        NumberAnimation {
                            duration: 50
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }

            // Percentage / Status Label
            Text {
                text: AudioService.outputMuted ? "Muted" : Math.round(AudioService.outputVolume * 100) + "%"
                color: AudioService.outputMuted ? Colors.color1 : Colors.foreground
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 12
                font.weight: Font.Bold
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
