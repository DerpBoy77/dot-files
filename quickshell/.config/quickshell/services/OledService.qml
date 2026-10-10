pragma Singleton
import QtQuick
import Quickshell.Hyprland

QtObject {
    id: root

    // =========================================================
    // Master OLED Protection Switch
    // =========================================================

    property bool enabled: true

    // =========================================================
    // Inactivity Dimming Engine
    // =========================================================

    readonly property real idleOpacity: 0.35
    readonly property real activeOpacity: 1.0
    readonly property int idleTimeoutMs: 3000

    property bool workspaceWaking: false

    property var workspaceWakeTimer: Timer {
        interval: root.idleTimeoutMs
        repeat: false
        onTriggered: {
            root.workspaceWaking = false;
        }
    }

    function wakeForWorkspace() {
        if (!enabled)
            return;
        workspaceWaking = true;
        workspaceWakeTimer.restart();
    }

    property var hyprlandConnections: Connections {
        target: Hyprland
        ignoreUnknownSignals: true
        function onFocusedWorkspaceChanged() {
            root.wakeForWorkspace();
        }
    }

    // =========================================================
    // Orbital Pixel Shift Engine (Burn-in Mitigation)
    // =========================================================

    readonly property int shiftIntervalMs: 120000 // Shift every 2 minutes
    property int shiftX: 0
    property int shiftY: 0
    property int orbitIndex: 0

    // 8-point subpixel orbit pattern to migrate static edges
    readonly property var orbitCoordinates: [
        [0, 0],
        [1, 0],
        [2, 1],
        [1, 2],
        [-1, 1],
        [-2, 0],
        [-1, -1],
        [0, -1]
    ]

    function advanceShift() {
        if (!enabled) {
            shiftX = 0;
            shiftY = 0;
            return;
        }
        orbitIndex = (orbitIndex + 1) % orbitCoordinates.length;
        let coord = orbitCoordinates[orbitIndex];
        shiftX = coord[0];
        shiftY = coord[1];
    }

    property var shiftTimer: Timer {
        interval: root.shiftIntervalMs
        repeat: true
        running: root.enabled
        onTriggered: root.advanceShift()
    }
}
