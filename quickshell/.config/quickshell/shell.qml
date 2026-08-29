//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import "./components"

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    // =========================================================
    // DYNAMIC TOP BAR (Survives DPMS on/off & Hotplugs)
    // =========================================================

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow

                // Dynamically binds to active output on wake-up
                required property var modelData
                screen: modelData

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
                    barWindow: barWindow

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
        }
    }
}
