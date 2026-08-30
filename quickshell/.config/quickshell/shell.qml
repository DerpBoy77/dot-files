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
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
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
