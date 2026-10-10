//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import "./"
import "./components"
import "./services"

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    Variants {
        model: Quickshell.screens

        delegate: Scope {
            id: screenScope
            required property var modelData

            // Top Bar Window
            PanelWindow {
                id: barWindow
                screen: screenScope.modelData

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

                property bool barHovered: false
                readonly property bool shouldBeAwake: {
                    if (!OledService.enabled)
                        return true;
                    if (barHovered)
                        return true;
                    if (OledService.workspaceWaking)
                        return true;
                    if (clock && clock.expanded)
                        return true;
                    if (systemPill && systemPill.popupShown)
                        return true;
                    if (NotificationService.hasActiveNotification)
                        return true;
                    return false;
                }

                property bool isAwake: true

                onShouldBeAwakeChanged: {
                    if (shouldBeAwake) {
                        idleTimer.stop();
                        isAwake = true;
                    } else {
                        idleTimer.restart();
                    }
                }

                Timer {
                    id: idleTimer
                    interval: OledService.idleTimeoutMs
                    repeat: false
                    onTriggered: {
                        if (!barWindow.shouldBeAwake) {
                            barWindow.isAwake = false;
                        }
                    }
                }

                // Non-blocking mouse tracker across the top bar
                MouseArea {
                    id: barMouseTracker
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onContainsMouseChanged: barWindow.barHovered = containsMouse
                }

                // Wrapped content for OLED orbital shift and idle dimming
                Item {
                    id: barContent
                    anchors.fill: parent

                    opacity: barWindow.isAwake ? OledService.activeOpacity : OledService.idleOpacity

                    Behavior on opacity {
                        NumberAnimation {
                            duration: barWindow.isAwake ? Theme.animOledWake : Theme.animOledDim
                            easing.type: Easing.InOutQuad
                        }
                    }

                    transform: Translate {
                        x: OledService.shiftX
                        y: OledService.shiftY

                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.animOledShift
                                easing.type: Easing.InOutQuad
                            }
                        }
                        Behavior on y {
                            NumberAnimation {
                                duration: Theme.animOledShift
                                easing.type: Easing.InOutQuad
                            }
                        }
                    }

                    // Left: Workspaces Pill
                    Workspaces {
                        anchors {
                            left: parent.left
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    // Center: Morphing Clock Pill
                    Clock {
                        id: clock
                        barWindow: barWindow

                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            verticalCenter: parent.verticalCenter
                        }
                    }

                    // Right: System Controls & Dynamic Island
                    SystemPill {
                        id: systemPill
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }

            // Fullscreen Volume Overlay
            VolumeOsd {
                screen: screenScope.modelData
            }
        }
    }
}
