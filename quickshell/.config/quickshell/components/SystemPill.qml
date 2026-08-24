import "../"
import "./popups"

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Hyprland

Rectangle {
    id: systemPill

    // =========================================================
    // Dynamic Glass & Palette Helpers
    // =========================================================

    readonly property color bgGlass: Colors.bgGlass !== undefined ? Colors.bgGlass : Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.70)
    readonly property color cardGlass: Colors.cardGlass !== undefined ? Colors.cardGlass : Qt.rgba(Colors.color0.r, Colors.color0.g, Colors.color0.b, 0.40)
    readonly property color borderGlass: Colors.borderGlass !== undefined ? Colors.borderGlass : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.16)
    readonly property color sectionHover: Colors.hoverOverlay !== undefined ? Colors.hoverOverlay : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.08)
    readonly property color sectionPressed: Colors.pressedOverlay !== undefined ? Colors.pressedOverlay : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.14)

    readonly property int sectionHeight: 24

    // =========================================================
    // Popup state machine
    // =========================================================

    readonly property int popupNone: 0
    readonly property int popupBluetooth: 1
    readonly property int popupNetwork: 2
    readonly property int popupAudio: 3

    property int popupType: popupNone
    property bool popupShown: false
    property bool popupExpanded: false
    property bool popupContentVisible: false

    signal popupOpened

    function stopPopupAnimations() {
        openAnimation.stop();
        closeAnimation.stop();
        switchAnimation.stop();
    }

    function openPopup(type) {
        stopPopupAnimations();
        trayMenu.close();
        popupType = type;
        openAnimation.restart();
        popupOpened();
    }

    function togglePopup(type) {
        if (popupShown && popupType === type) {
            closePopup();
            return;
        }
        if (popupShown) {
            stopPopupAnimations();
            switchAnimation.nextType = type;
            switchAnimation.restart();
            return;
        }
        openPopup(type);
    }

    function closePopup() {
        if (!popupShown)
            return;
        stopPopupAnimations();
        closeAnimation.restart();
    }

    // =========================================================
    // Animations
    // =========================================================

    SequentialAnimation {
        id: openAnimation
        ScriptAction {
            script: {
                popupShown = true;
                popupExpanded = false;
                popupContentVisible = false;
                dynamicPopup.anchor.updateAnchor();
            }
        }
        PauseAnimation {
            duration: 16
        }
        ScriptAction {
            script: {
                popupExpanded = true;
            }
        }
        PauseAnimation {
            duration: 100
        }
        ScriptAction {
            script: {
                popupContentVisible = true;
            }
        }
    }

    SequentialAnimation {
        id: closeAnimation
        ScriptAction {
            script: {
                popupContentVisible = false;
            }
        }
        PauseAnimation {
            duration: 80
        }
        ScriptAction {
            script: {
                popupExpanded = false;
            }
        }
        PauseAnimation {
            duration: 260
        }
        ScriptAction {
            script: {
                popupShown = false;
                popupType = popupNone;
            }
        }
    }

    SequentialAnimation {
        id: switchAnimation
        property int nextType: popupNone
        ScriptAction {
            script: {
                popupContentVisible = false;
            }
        }
        PauseAnimation {
            duration: 90
        }
        ScriptAction {
            script: {
                popupExpanded = false;
            }
        }
        PauseAnimation {
            duration: 180
        }
        ScriptAction {
            script: {
                popupType = switchAnimation.nextType;
                dynamicPopup.anchor.updateAnchor();
            }
        }
        PauseAnimation {
            duration: 20
        }
        ScriptAction {
            script: {
                popupExpanded = true;
            }
        }
        PauseAnimation {
            duration: 80
        }
        ScriptAction {
            script: {
                popupContentVisible = true;
                popupOpened();
            }
        }
    }

    // Dismiss with Escape key
    Shortcut {
        sequence: "Escape"
        enabled: systemPill.popupShown || trayMenu.shown
        onActivated: {
            if (trayMenu.shown) {
                trayMenu.close();
            } else if (systemPill.popupShown) {
                systemPill.closePopup();
            }
        }
    }

    // =========================================================
    // Main Pill Visuals
    // =========================================================

    color: popupShown ? "transparent" : systemPill.bgGlass
    radius: 12
    border.color: popupShown ? "transparent" : systemPill.borderGlass
    border.width: popupShown ? 0 : 1

    implicitHeight: 32
    implicitWidth: pillRow.implicitWidth + 16
    Layout.margins: 4

    opacity: popupShown && popupExpanded ? 0 : 1

    Behavior on opacity {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutQuad
        }
    }

    property bool hasWifi: {
        if (!Networking.devices)
            return false;
        for (let device of Networking.devices.values) {
            if (device.type === DeviceType.Wifi)
                return true;
        }
        return false;
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource].filter(Boolean)
    }

    // =========================================================
    // Pill Row (Tray, Bluetooth, Network, Audio)
    // =========================================================

    Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: 2
        enabled: !popupShown

        // System Tray
        Row {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: {
                    if (!SystemTray.items)
                        return [];
                    let filtered = [];
                    for (let item of SystemTray.items.values) {
                        let itemId = (item.id || "").toLowerCase();
                        let title = (item.title || "").toLowerCase();
                        if (itemId.includes("blueman") || itemId.includes("bluetooth") || title.includes("bluetooth") || itemId.includes("nm-applet") || itemId.includes("network") || title.includes("network")) {
                            continue;
                        }
                        filtered.push(item);
                    }
                    return filtered;
                }

                delegate: Rectangle {
                    id: trayDelegate
                    required property var modelData

                    width: 22
                    height: 22
                    radius: 6
                    color: trayMouse.pressed ? systemPill.sectionPressed : trayMouse.containsMouse ? systemPill.sectionHover : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                            easing.type: Easing.OutQuad
                        }
                    }

                    Item {
                        width: 16
                        height: 16
                        anchors.centerIn: parent

                        Image {
                            id: trayIconSrc
                            anchors.fill: parent
                            source: trayDelegate.modelData.icon || ""
                            sourceSize: Qt.size(16, 16)
                            visible: false
                        }

                        ColorOverlay {
                            anchors.fill: parent
                            source: trayIconSrc
                            color: trayMouse.containsMouse ? Colors.color4 : Colors.foreground

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                        onClicked: mouse => {
                            if (trayMenu.shown && trayMenu.anchorItem === trayDelegate) {
                                trayMenu.close();
                                return;
                            }
                            if (mouse.button === Qt.LeftButton) {
                                if (modelData.onlyMenu && modelData.hasMenu && modelData.menu) {
                                    trayMenu.open(modelData.menu, trayDelegate);
                                } else {
                                    trayMenu.close();
                                    modelData.activate();
                                }
                            } else if (mouse.button === Qt.MiddleButton) {
                                trayMenu.close();
                                if (modelData.secondaryActivate)
                                    modelData.secondaryActivate();
                                else
                                    modelData.activate();
                            } else if (mouse.button === Qt.RightButton) {
                                if (modelData.hasMenu && modelData.menu) {
                                    trayMenu.open(modelData.menu, trayDelegate);
                                } else if (modelData.secondaryActivate) {
                                    trayMenu.close();
                                    modelData.secondaryActivate();
                                } else {
                                    trayMenu.close();
                                    modelData.activate();
                                }
                            }
                        }

                        onWheel: wheel => {
                            if (modelData.scroll)
                                modelData.scroll(wheel.angleDelta.y, false);
                        }
                    }
                }
            }
        }

        // Bluetooth Toggle Button
        Rectangle {
            id: bluetoothToggle
            implicitWidth: 28
            implicitHeight: systemPill.sectionHeight
            radius: 8
            anchors.verticalCenter: parent.verticalCenter

            property var adapter: Bluetooth.defaultAdapter
            property bool powered: adapter !== null && adapter.enabled
            color: bluetoothMouse.pressed ? systemPill.sectionPressed : bluetoothMouse.containsMouse ? systemPill.sectionHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: bluetoothToggle.powered ? "󰂯" : "󰂲"
                color: bluetoothToggle.powered ? Colors.color4 : Colors.color8
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 15
            }

            MouseArea {
                id: bluetoothMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: systemPill.togglePopup(systemPill.popupBluetooth)
            }
        }

        // Network Toggle Button
        Rectangle {
            id: netSection
            implicitWidth: 28
            implicitHeight: systemPill.sectionHeight
            radius: 8
            anchors.verticalCenter: parent.verticalCenter

            property var activeDevice: {
                if (!Networking.devices)
                    return null;
                for (let device of Networking.devices.values) {
                    if (device.connected)
                        return device;
                }
                return null;
            }

            property bool wifiConnected: activeDevice !== null && activeDevice.type === DeviceType.Wifi
            property bool ethernetConnected: activeDevice !== null && activeDevice.type === DeviceType.Wired
            color: networkMouse.pressed ? systemPill.sectionPressed : networkMouse.containsMouse ? systemPill.sectionHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (netSection.wifiConnected)
                        return "󰤨";
                    if (netSection.ethernetConnected)
                        return "󰈀";
                    return systemPill.hasWifi ? "󰤭" : "󰈂";
                }
                color: (netSection.wifiConnected || netSection.ethernetConnected) ? Colors.color4 : Colors.color8
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 15
            }

            MouseArea {
                id: networkMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: systemPill.togglePopup(systemPill.popupNetwork)
            }
        }

        // Audio Toggle Button
        Rectangle {
            id: audioSection
            implicitWidth: audioRow.implicitWidth + 8
            implicitHeight: systemPill.sectionHeight
            radius: 8
            anchors.verticalCenter: parent.verticalCenter

            property var sink: Pipewire.defaultAudioSink
            color: audioMouse.pressed ? systemPill.sectionPressed : audioMouse.containsMouse ? systemPill.sectionHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }

            Row {
                id: audioRow
                anchors.centerIn: parent
                spacing: 5

                Text {
                    width: 18
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (!audioSection.sink || !audioSection.sink.audio)
                            return "󰕾";
                        if (audioSection.sink.audio.muted)
                            return "󰝟";
                        let volume = audioSection.sink.audio.volume;
                        if (volume <= 0.01)
                            return "󰝟";
                        if (volume < 0.33)
                            return "󰕿";
                        if (volume < 0.66)
                            return "󰖀";
                        return "󰕾";
                    }
                    color: (audioSection.sink && audioSection.sink.audio && audioSection.sink.audio.muted) ? Colors.color8 : Colors.color4
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 15
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (!audioSection.sink || !audioSection.sink.audio)
                            return "0%";
                        return Math.round(audioSection.sink.audio.volume * 100) + "%";
                    }
                    color: Colors.foreground
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 12
                }
            }

            MouseArea {
                id: audioMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton

                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton) {
                        systemPill.togglePopup(systemPill.popupAudio);
                        return;
                    }
                    if (audioSection.sink && audioSection.sink.audio) {
                        audioSection.sink.audio.muted = !audioSection.sink.audio.muted;
                    }
                }

                onWheel: wheel => {
                    if (!audioSection.sink || !audioSection.sink.audio)
                        return;
                    let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    audioSection.sink.audio.volume = Math.max(0, Math.min(1.0, audioSection.sink.audio.volume + delta));
                }
            }
        }
    }

    // =========================================================
    // Tray Context Menu Instance
    // =========================================================

    TrayContextMenu {
        id: trayMenu
        pill: systemPill
    }

    // =========================================================
    // Dynamic Island Window Container
    // =========================================================

    PopupWindow {
        id: dynamicPopup

        implicitWidth: 350
        implicitHeight: 900
        visible: systemPill.popupShown
        color: "transparent"

        anchor {
            item: systemPill
            edges: Edges.Top | Edges.Right
            gravity: Edges.Bottom | Edges.Left
        }

        mask: Region {
            item: island
        }
        HyprlandWindow.visibleMask: Region {
            item: island
        }

        onVisibleChanged: {
            if (visible)
                island.forceActiveFocus();
        }

        Rectangle {
            id: island
            anchors {
                top: parent.top
                right: parent.right
            }

            width: systemPill.popupExpanded ? parent.width : systemPill.width
            height: systemPill.popupExpanded ? (popupContent.item ? popupContent.item.implicitHeight : 32) : 32
            radius: systemPill.popupExpanded ? 16 : 12

            color: systemPill.bgGlass
            border.color: systemPill.borderGlass
            border.width: 1
            clip: true
            focus: true

            Keys.onEscapePressed: systemPill.closePopup()

            Behavior on width {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on radius {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Loader {
                id: popupContent
                anchors {
                    top: parent.top
                    left: parent.left
                }
                width: parent.width
                height: item ? item.implicitHeight : 0

                sourceComponent: {
                    if (systemPill.popupType === systemPill.popupBluetooth)
                        return bluetoothPopupComponent;
                    if (systemPill.popupType === systemPill.popupNetwork)
                        return networkPopupComponent;
                    if (systemPill.popupType === systemPill.popupAudio)
                        return audioPopupComponent;
                    return null;
                }

                opacity: systemPill.popupContentVisible ? 1 : 0
                y: systemPill.popupContentVisible ? 0 : -8
                scale: systemPill.popupContentVisible ? 1 : 0.985
                transformOrigin: Item.TopRight

                Behavior on opacity {
                    NumberAnimation {
                        duration: 140
                        easing.type: Easing.OutQuad
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [dynamicPopup]
        active: systemPill.popupShown
        onCleared: {
            if (systemPill.popupShown)
                systemPill.closePopup();
        }
    }

    Component {
        id: bluetoothPopupComponent
        BluetoothPopup {
            pill: systemPill
        }
    }
    Component {
        id: networkPopupComponent
        NetworkPopup {
            pill: systemPill
        }
    }
    Component {
        id: audioPopupComponent
        AudioPopup {
            pill: systemPill
        }
    }
}
