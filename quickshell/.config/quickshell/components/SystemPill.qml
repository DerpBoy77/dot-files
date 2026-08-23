import "../"

import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Pipewire
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: systemPill

    // =========================================================
    // Dynamic Glass & Palette Helpers (Consistent with Kitty 0.7)
    // =========================================================

    readonly property color bgGlass: Colors.bgGlass !== undefined ? Colors.bgGlass : Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.70)
    readonly property color cardGlass: Colors.cardGlass !== undefined ? Colors.cardGlass : Qt.rgba(Colors.color0.r, Colors.color0.g, Colors.color0.b, 0.40)
    readonly property color borderGlass: Colors.borderGlass !== undefined ? Colors.borderGlass : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.16)
    readonly property color sectionHover: Colors.hoverOverlay !== undefined ? Colors.hoverOverlay : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.08)
    readonly property color sectionPressed: Colors.pressedOverlay !== undefined ? Colors.pressedOverlay : Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.14)

    readonly property int sectionHeight: 24

    // =========================================================
    // Popup state
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

    // =========================================================
    // Active Custom Context Menu State & Animated Lifecycle
    // =========================================================

    property var activeTrayMenuHandle: null
    property var activeTrayAnchorItem: null
    property bool trayMenuShown: false
    property bool trayMenuExpanded: false
    readonly property bool trayMenuVisible: activeTrayMenuHandle !== null

    function openTrayMenu(menuHandle, anchorItem) {
        if (!menuHandle)
            return;
        closeTrayMenuTimer.stop();
        closePopup();

        activeTrayMenuHandle = menuHandle;
        activeTrayAnchorItem = anchorItem;
        trayMenuShown = true;
        trayMenuExpanded = false;

        Qt.callLater(function () {
            if (!systemPill.trayMenuShown)
                return;
            customTrayMenuPopup.anchor.updateAnchor();

            Qt.callLater(function () {
                if (systemPill.trayMenuShown) {
                    systemPill.trayMenuExpanded = true;
                }
            });
        });
    }

    function closeTrayMenu() {
        if (!trayMenuShown)
            return;
        trayMenuExpanded = false;
        closeTrayMenuTimer.restart();
    }

    Timer {
        id: closeTrayMenuTimer
        interval: 180
        repeat: false
        onTriggered: {
            systemPill.trayMenuShown = false;
            systemPill.activeTrayMenuHandle = null;
            systemPill.activeTrayAnchorItem = null;
        }
    }

    // =========================================================
    // Main pill
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

    // Keyboard Dismissal (Escape key)
    Shortcut {
        sequence: "Escape"
        enabled: systemPill.popupShown || systemPill.trayMenuShown
        onActivated: {
            if (systemPill.trayMenuShown) {
                systemPill.closeTrayMenu();
            } else if (systemPill.popupShown) {
                systemPill.closePopup();
            }
        }
    }

    // =========================================================
    // Popup animation state machine
    // =========================================================

    function stopPopupAnimations() {
        openAnimation.stop();
        closeAnimation.stop();
        switchAnimation.stop();
    }

    function openPopup(type) {
        stopPopupAnimations();
        systemPill.closeTrayMenu();
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

    // Animations
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
    // Main pill contents
    // =========================================================

    Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: 2
        enabled: !popupShown

        // =====================================================
        // System tray
        // =====================================================

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

                    IconImage {
                        width: 16
                        height: 16
                        anchors.centerIn: parent
                        source: modelData.icon || ""
                        implicitSize: 16
                    }

                    MouseArea {
                        id: trayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

                        onClicked: mouse => {
                            if (systemPill.trayMenuShown && systemPill.activeTrayAnchorItem === trayDelegate) {
                                systemPill.closeTrayMenu();
                                return;
                            }

                            if (mouse.button === Qt.LeftButton) {
                                if (modelData.onlyMenu && modelData.hasMenu && modelData.menu) {
                                    systemPill.openTrayMenu(modelData.menu, trayDelegate);
                                } else {
                                    systemPill.closeTrayMenu();
                                    modelData.activate();
                                }
                            } else if (mouse.button === Qt.MiddleButton) {
                                systemPill.closeTrayMenu();
                                if (modelData.secondaryActivate) {
                                    modelData.secondaryActivate();
                                } else {
                                    modelData.activate();
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                if (modelData.hasMenu && modelData.menu) {
                                    systemPill.openTrayMenu(modelData.menu, trayDelegate);
                                } else if (modelData.secondaryActivate) {
                                    systemPill.closeTrayMenu();
                                    modelData.secondaryActivate();
                                } else {
                                    systemPill.closeTrayMenu();
                                    modelData.activate();
                                }
                            }
                        }

                        onWheel: wheel => {
                            if (modelData.scroll) {
                                modelData.scroll(wheel.angleDelta.y, false);
                            }
                        }
                    }
                }
            }
        }

        // Bluetooth button
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
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                id: bluetoothMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: systemPill.togglePopup(systemPill.popupBluetooth)
            }
        }

        // Network button
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
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                id: networkMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: systemPill.togglePopup(systemPill.popupNetwork)
            }
        }

        // Audio button
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
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
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
    // Custom Themed Context Menu Popup Window with Animations
    // =========================================================

    PopupWindow {
        id: customTrayMenuPopup

        visible: systemPill.trayMenuShown && systemPill.activeTrayAnchorItem !== null
        implicitWidth: menuCard.implicitWidth + 24
        implicitHeight: menuCard.implicitHeight + 24
        color: "transparent"

        anchor {
            item: systemPill.activeTrayAnchorItem || systemPill
            edges: Edges.Bottom | Edges.Right
            gravity: Edges.Bottom | Edges.Left
        }

        onVisibleChanged: {
            if (visible) {
                anchor.updateAnchor();
            } else if (systemPill.trayMenuShown) {
                systemPill.closeTrayMenu();
            }
        }

        QsMenuOpener {
            id: trayOpener
            menu: systemPill.activeTrayMenuHandle
        }

        Rectangle {
            id: menuCard

            anchors {
                top: parent.top
                right: parent.right
            }

            implicitWidth: Math.max(160, menuItemsColumn.implicitWidth + 16)
            implicitHeight: menuItemsColumn.implicitHeight + 16
            radius: 12
            color: systemPill.bgGlass
            border.color: systemPill.borderGlass
            border.width: 1
            clip: true

            transformOrigin: Item.TopRight

            // Crisp Spring & Fade Animation matching Clock.qml
            opacity: systemPill.trayMenuExpanded ? 1 : 0
            scale: systemPill.trayMenuExpanded ? 1 : 0.90
            y: systemPill.trayMenuExpanded ? 0 : -6

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.04
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 240
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                id: menuItemsColumn
                anchors.centerIn: parent
                width: parent.implicitWidth - 16
                spacing: 3

                Repeater {
                    model: trayOpener.children

                    delegate: Item {
                        id: menuItemDelegate
                        required property var modelData

                        width: menuItemsColumn.width
                        height: modelData.isSeparator ? 9 : 28
                        implicitHeight: height

                        Rectangle {
                            visible: menuItemDelegate.modelData.isSeparator
                            anchors.centerIn: parent
                            width: parent.width
                            height: 1
                            color: systemPill.borderGlass
                        }

                        Rectangle {
                            visible: !menuItemDelegate.modelData.isSeparator
                            anchors.fill: parent
                            radius: 6
                            color: itemMouse.containsMouse ? systemPill.cardGlass : "transparent"
                            opacity: menuItemDelegate.modelData.enabled !== false ? 1 : 0.4

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                    easing.type: Easing.OutQuad
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    visible: menuItemDelegate.modelData.checkState !== undefined && menuItemDelegate.modelData.checkState !== Qt.Unchecked
                                    text: "󰄬"
                                    color: Colors.color4
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 11
                                }

                                IconImage {
                                    visible: (menuItemDelegate.modelData.icon || "") !== ""
                                    source: menuItemDelegate.modelData.icon || ""
                                    width: 14
                                    height: 14
                                    implicitSize: 14
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (menuItemDelegate.modelData.text || "").replace(/_([a-zA-Z0-9])/g, "$1")
                                    color: itemMouse.containsMouse ? Colors.color4 : Colors.foreground
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: menuItemDelegate.modelData.hasChildren
                                    text: "󰅂"
                                    color: Colors.color8
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: menuItemDelegate.modelData.enabled !== false

                                onClicked: {
                                    systemPill.closeTrayMenu();
                                    menuItemDelegate.modelData.triggered();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Dismiss custom context menu when clicking outside
    HyprlandFocusGrab {
        id: menuFocusGrab
        windows: [customTrayMenuPopup]
        active: systemPill.trayMenuShown

        onCleared: {
            systemPill.closeTrayMenu();
        }
    }

    // =========================================================
    // Network telemetry (IP, Gateway, Link Speed, Interface)
    // =========================================================

    Process {
        id: netStatsProc
        command: ["sh", "-c", "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"dev\") {print $(i+1); exit}}'); " + "if [ -z \"$iface\" ]; then " + "iface=$(ip -o link show 2>/dev/null | awk -F': ' '$2 !~ /^lo$/ {print $2; exit}'); " + "fi; " + "ip=$(ip -4 -o addr show dev \"$iface\" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1); " + "if [ -z \"$ip\" ]; then " + "ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"src\") {print $(i+1); exit}}'); " + "fi; " + "gw=$(ip -4 route show default 2>/dev/null | awk 'NR==1 {print $3}'); " + "speed=''; " + "if [ -n \"$iface\" ]; then " + "speed=$(iw dev \"$iface\" link 2>/dev/null | sed -n 's/.*tx bitrate: \\([0-9.]* [^ ]*\\).*/\\1/p' | head -n1); " + "if [ -z \"$speed\" ] && [ -r \"/sys/class/net/$iface/speed\" ]; then " + "raw_speed=$(cat \"/sys/class/net/$iface/speed\" 2>/dev/null); " + "if [ -n \"$raw_speed\" ] && [ \"$raw_speed\" -gt 0 ] 2>/dev/null; then " + "if [ \"$raw_speed\" -ge 1000 ]; then " + "speed=\"$((raw_speed / 1000)) Gbps\"; " + "else " + "speed=\"${raw_speed} Mbps\"; " + "fi; " + "fi; " + "fi; " + "if [ -z \"$speed\" ]; then " + "speed=$(iwconfig \"$iface\" 2>/dev/null | sed -n 's/.*Bit Rate=\\([0-9.]* [^ ]*\\).*/\\1/p' | head -n1); " + "fi; " + "fi; " + "printf '%s|%s|%s|%s' \"${ip:-Unknown}\" \"${gw:-Unknown}\" \"${speed:-N/A}\" \"${iface:-Unknown}\""]

        stdout: StdioCollector {
            id: netStatsOut
            onStreamFinished: {
                let output = netStatsOut.text.trim();
                let parts = output.split("|");
                if (parts.length >= 4) {
                    dynamicPopup.dynamicIp = parts[0] || "Unknown";
                    dynamicPopup.dynamicGw = parts[1] || "Unknown";
                    dynamicPopup.dynamicSpeed = parts[2] || "N/A";
                    dynamicPopup.dynamicIface = parts[3] || "Unknown";
                }
            }
        }
    }

    // =========================================================
    // Dynamic island window
    // =========================================================

    PopupWindow {
        id: dynamicPopup

        implicitWidth: 350
        implicitHeight: 900

        visible: systemPill.popupShown
        color: "transparent"

        property string dynamicIp: "Unknown"
        property string dynamicGw: "Unknown"
        property string dynamicSpeed: "N/A"
        property string dynamicIface: "Unknown"

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
            if (visible) {
                island.forceActiveFocus();
                if (systemPill.popupType === systemPill.popupNetwork) {
                    netStatsProc.running = true;
                }
            }
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

            Keys.onEscapePressed: {
                systemPill.closePopup();
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    systemPill.closePopup();
                    event.accepted = true;
                }
            }

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
            if (systemPill.popupShown) {
                systemPill.closePopup();
            }
        }
    }

    // Bluetooth popup component
    component BluetoothPopupContent: Item {
        id: bluetoothPopup

        readonly property var adapter: Bluetooth.defaultAdapter

        implicitWidth: 350
        implicitHeight: bluetoothColumn.implicitHeight + 32

        function deviceName(device) {
            if (!device)
                return "Unknown Device";
            return device.name || device.deviceName || device.alias || device.address || "Unknown Device";
        }

        function deviceStatus(device) {
            if (!device)
                return "Unknown";
            if (device.connected)
                return "Connected";
            if (device.pairing)
                return "Pairing…";
            if (device.paired)
                return "Paired";
            return "Available";
        }

        function sortedDevices() {
            if (!Bluetooth.devices)
                return [];
            let devices = Bluetooth.devices.values.slice();
            devices.sort((a, b) => {
                if (a.connected && !b.connected)
                    return -1;
                if (!a.connected && b.connected)
                    return 1;
                if (a.paired && !b.paired)
                    return -1;
                if (!a.paired && b.paired)
                    return 1;
                return ((a.name || "").localeCompare(b.name || ""));
            });
            return devices.slice(0, 10);
        }

        function deviceIcon(device) {
            if (!device)
                return "󰂯";
            let icon = (device.icon || "").toLowerCase();
            let name = (device.name || "").toLowerCase();
            if (icon.includes("headset") || icon.includes("audio") || name.includes("buds") || name.includes("headphone") || name.includes("wh-") || name.includes("airpod")) {
                return "󰋋";
            }
            if (icon.includes("keyboard") || name.includes("keyboard"))
                return "󰌌";
            if (icon.includes("mouse") || name.includes("mouse") || name.includes("touchpad"))
                return "󰍽";
            if (icon.includes("phone") || name.includes("phone"))
                return "󰄜";
            return device.connected ? "󰂱" : "󰂯";
        }

        Column {
            id: bluetoothColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            anchors.margins: 16
            spacing: 14

            RowLayout {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? Colors.color4 : systemPill.cardGlass

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? "󰂯" : "󰂲"
                        color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? Colors.background : Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 21
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Bluetooth"
                        color: Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Text {
                        text: !bluetoothPopup.adapter ? "Unavailable" : bluetoothPopup.adapter.enabled ? (bluetoothPopup.adapter.discovering ? "Scanning…" : "On") : "Off"
                        color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled && bluetoothPopup.adapter.discovering ? Colors.color4 : Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    width: 46
                    height: 26
                    radius: 13
                    color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? Colors.color4 : systemPill.cardGlass
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                    }

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: Colors.background
                        anchors.verticalCenter: parent.verticalCenter
                        x: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? parent.width - width - 2 : 2

                        Behavior on x {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutExpo
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: bluetoothPopup.adapter !== null
                        onClicked: {
                            bluetoothPopup.adapter.enabled = !bluetoothPopup.adapter.enabled;
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                implicitHeight: 1
                color: systemPill.borderGlass
            }

            RowLayout {
                width: parent.width
                spacing: 8

                Text {
                    text: "Devices"
                    color: Colors.color8
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: (bluetoothPopup.adapter && bluetoothPopup.adapter.discovering) ? 76 : 60
                    height: 24
                    radius: 6
                    visible: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled
                    color: scanBtMouse.containsMouse ? systemPill.cardGlass : "transparent"
                    border.color: systemPill.borderGlass
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: (bluetoothPopup.adapter && bluetoothPopup.adapter.discovering) ? "Scanning…" : "Scan"
                        color: (bluetoothPopup.adapter && bluetoothPopup.adapter.discovering) ? Colors.color4 : Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: scanBtMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (bluetoothPopup.adapter) {
                                bluetoothPopup.adapter.discovering = !bluetoothPopup.adapter.discovering;
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: bluetoothPopup.sortedDevices()

                    delegate: Rectangle {
                        id: deviceRow
                        required property var modelData

                        width: parent.width
                        height: 48
                        implicitHeight: 48
                        radius: 9
                        color: deviceMouse.containsMouse ? systemPill.cardGlass : modelData.connected ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.10) : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: 110
                                easing.type: Easing.OutQuad
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 10

                            Rectangle {
                                width: 30
                                height: 30
                                radius: 15
                                color: modelData.connected ? Colors.color4 : systemPill.cardGlass
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: bluetoothPopup.deviceIcon(modelData)
                                    color: modelData.connected ? Colors.background : Colors.color8
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 15
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    width: parent.width
                                    text: bluetoothPopup.deviceName(modelData)
                                    color: modelData.connected ? Colors.color4 : Colors.foreground
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Row {
                                    spacing: 6
                                    Text {
                                        text: bluetoothPopup.deviceStatus(modelData)
                                        color: modelData.connected ? Colors.color4 : Colors.color8
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        visible: modelData.connected && modelData.batteryAvailable
                                        text: "• 󰥉 " + Math.round((modelData.battery || 0) * 100) + "%"
                                        color: Colors.color8
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            Rectangle {
                                id: deviceAction
                                width: modelData.connected ? 82 : modelData.paired ? 68 : 54
                                height: 28
                                radius: 7
                                color: actionMouse.containsMouse ? (modelData.connected ? Colors.background : Colors.color4) : modelData.connected ? "transparent" : Colors.color4
                                border.color: modelData.connected ? systemPill.borderGlass : "transparent"
                                border.width: modelData.connected ? 1 : 0
                                Layout.alignment: Qt.AlignVCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.connected ? "Disconnect" : modelData.pairing ? "Pairing…" : modelData.paired ? "Connect" : "Pair"
                                    color: modelData.connected ? Colors.foreground : Colors.background
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !modelData.pairing

                                    onClicked: {
                                        if (modelData.connected) {
                                            modelData.disconnect();
                                        } else if (modelData.paired) {
                                            modelData.connect();
                                        } else {
                                            modelData.pair();
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: deviceMouse
                            anchors.fill: parent
                            anchors.rightMargin: deviceAction.width + 8
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 70
                implicitHeight: 70
                radius: 10
                color: systemPill.cardGlass
                visible: !Bluetooth.devices || Bluetooth.devices.values.length === 0

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰂲"
                        color: Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 20
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? "No devices found" : "Bluetooth is off"
                        color: Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    Component {
        id: bluetoothPopupComponent
        BluetoothPopupContent {}
    }

    // Network popup component
    component NetworkPopupContent: Item {
        id: wifiPopup

        readonly property var wifiDevice: {
            if (!Networking.devices)
                return null;
            for (let device of Networking.devices.values) {
                if (device.type === DeviceType.Wifi)
                    return device;
            }
            return null;
        }

        readonly property var ethernetDevice: {
            if (!Networking.devices)
                return null;
            for (let device of Networking.devices.values) {
                if (device.type === DeviceType.Wired)
                    return device;
            }
            return null;
        }

        readonly property bool hasWifi: wifiDevice !== null
        readonly property bool hasEthernet: ethernetDevice !== null
        readonly property bool ethernetConnected: ethernetDevice !== null && ethernetDevice.connected

        readonly property var connectedWifiNetwork: {
            let device = wifiPopup.wifiDevice;
            if (!device || !device.networks)
                return null;
            for (let network of device.networks.values) {
                if (network.connected)
                    return network;
            }
            return null;
        }

        Component.onCompleted: {
            netStatsProc.running = true;
        }

        implicitWidth: 350
        implicitHeight: wifiPopup.hasWifi ? wifiColumn.implicitHeight + 32 : ethernetColumn.implicitHeight + 32

        function signalIcon(strength) {
            if (strength >= 0.75)
                return "󰤨";
            if (strength >= 0.50)
                return "󰤥";
            if (strength >= 0.25)
                return "󰤢";
            if (strength > 0.05)
                return "󰤟";
            return "󰤯";
        }

        function signalColor(strength, connected) {
            if (connected)
                return Colors.color4;
            if (strength >= 0.50)
                return Colors.foreground;
            return Colors.color8;
        }

        function sortedNetworks() {
            let device = wifiPopup.wifiDevice;
            if (!device || !device.networks)
                return [];
            let networks = device.networks.values.slice();
            networks.sort((a, b) => {
                if (a.connected && !b.connected)
                    return -1;
                if (!a.connected && b.connected)
                    return 1;
                if (a.known && !b.known)
                    return -1;
                if (!a.known && b.known)
                    return 1;
                return (b.signalStrength - a.signalStrength);
            });
            return networks.slice(0, 8);
        }

        Column {
            id: wifiColumn
            visible: wifiPopup.hasWifi
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            anchors.margins: 16
            spacing: 14

            RowLayout {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 44
                    height: 44
                    radius: 22
                    color: Networking.wifiEnabled ? Colors.color4 : systemPill.cardGlass

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (!Networking.wifiEnabled)
                                return "󰤭";
                            if (wifiPopup.connectedWifiNetwork) {
                                return wifiPopup.signalIcon(wifiPopup.connectedWifiNetwork.signalStrength);
                            }
                            return "󰤭";
                        }
                        color: Networking.wifiEnabled ? Colors.background : Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 21
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Wi-Fi"
                        color: Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }

                    Text {
                        width: parent.width
                        text: {
                            if (!Networking.wifiEnabled)
                                return "Off";
                            if (wifiPopup.connectedWifiNetwork) {
                                return wifiPopup.connectedWifiNetwork.name || "Connected";
                            }
                            return "Not connected";
                        }
                        color: wifiPopup.connectedWifiNetwork ? Colors.color4 : Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    width: 46
                    height: 26
                    radius: 13
                    color: Networking.wifiEnabled ? Colors.color4 : systemPill.cardGlass
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                    }

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        color: Colors.background
                        anchors.verticalCenter: parent.verticalCenter
                        x: Networking.wifiEnabled ? parent.width - width - 2 : 2

                        Behavior on x {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutExpo
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Networking.wifiEnabled = !Networking.wifiEnabled;
                        }
                    }
                }
            }

            // Quick Network Stats Card with Link Speed
            Rectangle {
                width: parent.width
                height: 38
                implicitHeight: 38
                radius: 8
                color: systemPill.cardGlass
                border.color: systemPill.borderGlass
                border.width: 1
                visible: Networking.wifiEnabled && (wifiPopup.connectedWifiNetwork !== null)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: "󰩟 " + dynamicPopup.dynamicIp
                        color: Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 10
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: "󰛳 " + dynamicPopup.dynamicSpeed
                        color: Colors.color4
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                visible: Networking.wifiEnabled && wifiPopup.connectedWifiNetwork !== null

                Text {
                    text: "Connected"
                    color: Colors.color8
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: parent.width
                    height: 68
                    implicitHeight: 68
                    radius: 10
                    color: Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.12)
                    border.color: Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.20)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 10

                        Rectangle {
                            width: 34
                            height: 34
                            radius: 17
                            color: Colors.color4
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: wifiPopup.signalIcon(wifiPopup.connectedWifiNetwork ? wifiPopup.connectedWifiNetwork.signalStrength : 1)
                                color: Colors.background
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 17
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                width: parent.width
                                text: wifiPopup.connectedWifiNetwork ? (wifiPopup.connectedWifiNetwork.name || "Connected") : "Connected"
                                color: Colors.color4
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: wifiPopup.connectedWifiNetwork && wifiPopup.connectedWifiNetwork.stateChanging ? "Connecting…" : (dynamicPopup.dynamicGw !== "Unknown" ? ("GW: " + dynamicPopup.dynamicGw) : "Active connection")
                                color: Colors.color8
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: "󰄬"
                            color: Colors.color4
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 18
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 6
                visible: Networking.wifiEnabled

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Available Networks"
                        color: Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: wifiPopup.wifiDevice && wifiPopup.wifiDevice.scannerEnabled ? 80 : 62
                        height: 24
                        radius: 6
                        color: scanMouse.containsMouse ? systemPill.cardGlass : "transparent"
                        border.color: systemPill.borderGlass
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: wifiPopup.wifiDevice && wifiPopup.wifiDevice.scannerEnabled ? "Scanning…" : "Refresh"
                            color: wifiPopup.wifiDevice && wifiPopup.wifiDevice.scannerEnabled ? Colors.color4 : Colors.foreground
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 10
                        }

                        MouseArea {
                            id: scanMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: wifiPopup.wifiDevice !== null
                            onClicked: {
                                if (wifiPopup.wifiDevice) {
                                    wifiPopup.wifiDevice.scannerEnabled = !wifiPopup.wifiDevice.scannerEnabled;
                                    netStatsProc.running = true;
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 3

                    Repeater {
                        model: wifiPopup.sortedNetworks()

                        delegate: Rectangle {
                            id: networkRow
                            required property var modelData

                            width: parent.width
                            height: 48
                            implicitHeight: 48
                            radius: 9
                            color: networkMouse.containsMouse ? systemPill.cardGlass : modelData.connected ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.08) : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 110
                                    easing.type: Easing.OutQuad
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 10

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: modelData.connected ? Colors.color4 : systemPill.cardGlass
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        anchors.centerIn: parent
                                        text: wifiPopup.signalIcon(modelData.signalStrength)
                                        color: modelData.connected ? Colors.background : wifiPopup.signalColor(modelData.signalStrength, modelData.connected)
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        font.pixelSize: 15
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter

                                    Text {
                                        width: parent.width
                                        text: modelData.name || "Hidden Network"
                                        color: modelData.connected ? Colors.color4 : Colors.foreground
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        font.pixelSize: 12
                                        font.weight: modelData.connected ? Font.Bold : Font.Medium
                                        elide: Text.ElideRight
                                    }

                                    Row {
                                        spacing: 5
                                        Text {
                                            text: modelData.connected ? "Connected" : modelData.stateChanging ? "Connecting…" : modelData.known ? "Saved" : "Available"
                                            color: modelData.connected ? Colors.color4 : modelData.stateChanging ? Colors.color4 : Colors.color8
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                            font.pixelSize: 9
                                        }

                                        Text {
                                            visible: modelData.security !== undefined && modelData.security !== WifiSecurityType.Open
                                            text: "• 󰌾"
                                            color: Colors.color8
                                            font.family: "JetBrainsMono Nerd Font Propo"
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                Rectangle {
                                    width: modelData.connected ? 82 : modelData.stateChanging ? 88 : 68
                                    height: 28
                                    radius: 7
                                    Layout.alignment: Qt.AlignVCenter
                                    color: networkActionMouse.containsMouse ? (modelData.connected ? Colors.background : Colors.color4) : modelData.connected ? "transparent" : Colors.color4
                                    border.color: modelData.connected ? systemPill.borderGlass : "transparent"
                                    border.width: modelData.connected ? 1 : 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.connected ? "Disconnect" : modelData.stateChanging ? "Connecting…" : "Connect"
                                        color: modelData.connected ? Colors.foreground : Colors.background
                                        font.family: "JetBrainsMono Nerd Font Propo"
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                    }

                                    MouseArea {
                                        id: networkActionMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !modelData.stateChanging

                                        onClicked: {
                                            if (modelData.connected) {
                                                modelData.disconnect();
                                            } else {
                                                modelData.connect();
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: networkMouse
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    bottom: parent.bottom
                                    right: networkActionMouse.left
                                }
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }
            }

            Text {
                visible: wifiPopup.connectedWifiNetwork && wifiPopup.connectedWifiNetwork.known
                text: "Forget current network"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: forgetMouse.containsMouse ? Colors.foreground : Colors.color8
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 10
                font.weight: Font.Medium

                MouseArea {
                    id: forgetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (wifiPopup.connectedWifiNetwork) {
                            wifiPopup.connectedWifiNetwork.forget();
                        }
                    }
                }
            }
        }

        Column {
            id: ethernetColumn
            visible: !wifiPopup.hasWifi
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            anchors.margins: 16
            spacing: 14

            RowLayout {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    color: wifiPopup.ethernetConnected ? Colors.color4 : systemPill.cardGlass

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: wifiPopup.ethernetConnected ? "󰈀" : "󰈂"
                        color: wifiPopup.ethernetConnected ? Colors.background : Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 22
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Ethernet"
                        color: Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                    }

                    Text {
                        text: wifiPopup.ethernetConnected ? "Connected" : "Disconnected"
                        color: wifiPopup.ethernetConnected ? Colors.color4 : Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: ethernetDetailsColumn.implicitHeight + 28
                implicitHeight: ethernetDetailsColumn.implicitHeight + 28
                radius: 12
                color: systemPill.cardGlass
                border.color: systemPill.borderGlass
                border.width: 1

                Column {
                    id: ethernetDetailsColumn
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        width: parent.width
                        Text {
                            text: "IP Address"
                            color: Colors.color8
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }
                        Text {
                            text: dynamicPopup.dynamicIp
                            color: Colors.foreground
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        implicitHeight: 1
                        color: systemPill.borderGlass
                    }

                    RowLayout {
                        width: parent.width
                        Text {
                            text: "Link Speed"
                            color: Colors.color8
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }
                        Text {
                            text: dynamicPopup.dynamicSpeed
                            color: Colors.foreground
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        implicitHeight: 1
                        color: systemPill.borderGlass
                    }

                    RowLayout {
                        width: parent.width
                        Text {
                            text: "Interface"
                            color: Colors.color8
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }
                        Text {
                            text: dynamicPopup.dynamicIface
                            color: Colors.foreground
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    Component {
        id: networkPopupComponent
        NetworkPopupContent {}
    }

    // Audio popup component
    component AudioPopupContent: Item {
        id: audioPopup

        implicitWidth: 350
        implicitHeight: audioColumn.implicitHeight + 36

        readonly property var output: Pipewire.defaultAudioSink
        readonly property var input: Pipewire.defaultAudioSource

        property real fallbackInputVolume: 1.0
        property bool fallbackInputMuted: false

        readonly property var sinkNodes: {
            if (!Pipewire.nodes)
                return [];
            let list = [];
            for (let node of Pipewire.nodes.values) {
                if (!node || node.isStream || !node.isSink || !node.audio)
                    continue;
                list.push(node);
            }
            return list;
        }

        readonly property var mixerStreams: {
            if (!Pipewire.nodes)
                return [];
            let streams = [];
            for (let node of Pipewire.nodes.values) {
                if (!node || !node.isStream || !node.isSink || !node.audio)
                    continue;
                streams.push(node);
            }
            streams.sort((a, b) => {
                let an = audioPopup.nodeAppName(a).toLowerCase();
                let bn = audioPopup.nodeAppName(b).toLowerCase();
                return an.localeCompare(bn);
            });
            return streams;
        }

        PwObjectTracker {
            objects: [audioPopup.output, audioPopup.input, ...audioPopup.sinkNodes, ...audioPopup.mixerStreams].filter(Boolean)
        }

        readonly property var outputAudio: audioPopup.output && audioPopup.output.audio ? audioPopup.output.audio : null
        readonly property var inputAudio: audioPopup.input && audioPopup.input.audio ? audioPopup.input.audio : null

        readonly property bool outputAvailable: audioPopup.output !== null
        readonly property bool inputAvailable: audioPopup.input !== null

        Process {
            id: wpctlGetSourceProc
            command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    let out = text.trim();
                    if (out.startsWith("Volume:")) {
                        let clean = out.replace("Volume:", "").trim();
                        let parts = clean.split(" ");
                        let vol = parseFloat(parts[0]);
                        if (!isNaN(vol)) {
                            audioPopup.fallbackInputVolume = Math.max(0, Math.min(1.0, vol));
                        }
                        audioPopup.fallbackInputMuted = out.includes("[MUTED]");
                    }
                }
            }
        }

        Process {
            id: wpctlSetSourceVolProc
            property string targetVol: "1.0"
            command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", targetVol]
        }

        Process {
            id: wpctlToggleSourceMuteProc
            command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
        }

        Component.onCompleted: {
            wpctlGetSourceProc.running = true;
        }

        function nodeAppName(node) {
            if (!node)
                return "Unknown Application";
            let properties = node.properties;
            if (properties) {
                if (properties["application.name"])
                    return properties["application.name"];
                if (properties["media.name"])
                    return properties["media.name"];
                if (properties["node.description"])
                    return properties["node.description"];
            }
            return (node.description || node.nickname || node.name || "Unknown Application");
        }

        function outputVolume() {
            let audio = audioPopup.outputAudio;
            if (!audio)
                return 0;
            let volume = Number(audio.volume);
            return isNaN(volume) ? 0 : Math.max(0, Math.min(1.0, volume));
        }

        function inputVolume() {
            let audio = audioPopup.inputAudio;
            if (audio && audio.volume !== undefined && !isNaN(Number(audio.volume))) {
                return Math.max(0, Math.min(1.0, Number(audio.volume)));
            }
            return audioPopup.fallbackInputVolume;
        }

        function outputMuted() {
            return audioPopup.outputAudio ? !!audioPopup.outputAudio.muted : false;
        }

        function inputMuted() {
            if (audioPopup.inputAudio && audioPopup.inputAudio.muted !== undefined) {
                return !!audioPopup.inputAudio.muted;
            }
            return audioPopup.fallbackInputMuted;
        }

        function outputIcon() {
            let audio = audioPopup.outputAudio;
            if (!audio)
                return "󰕾";
            if (audio.muted)
                return "󰝟";
            let volume = Number(audio.volume) || 0;
            if (volume <= 0.01)
                return "󰝟";
            if (volume < 0.33)
                return "󰕿";
            if (volume < 0.66)
                return "󰖀";
            return "󰕾";
        }

        function inputIcon() {
            return audioPopup.inputMuted() ? "󰍭" : "󰍬";
        }

        function outputName() {
            let node = audioPopup.output;
            if (!node)
                return "No Output";
            return (node.description || node.nickname || node.name || "Speakers");
        }

        function inputName() {
            let node = audioPopup.input;
            if (!node)
                return "No Microphone";
            return (node.description || node.nickname || node.name || "Microphone");
        }

        function setOutputVolume(value) {
            let audio = audioPopup.outputAudio;
            if (audio)
                audio.volume = Math.max(0, Math.min(1.0, value));
        }

        function setInputVolume(value) {
            let val = Math.max(0, Math.min(1.0, value));
            audioPopup.fallbackInputVolume = val;
            let audio = audioPopup.inputAudio;
            if (audio) {
                audio.volume = val;
            }
            wpctlSetSourceVolProc.targetVol = val.toFixed(2);
            wpctlSetSourceVolProc.running = true;
        }

        function toggleInputMute() {
            let audio = audioPopup.inputAudio;
            if (audio) {
                audio.muted = !audio.muted;
                audioPopup.fallbackInputMuted = audio.muted;
            } else {
                audioPopup.fallbackInputMuted = !audioPopup.fallbackInputMuted;
            }
            wpctlToggleSourceMuteProc.running = true;
        }

        Column {
            id: audioColumn
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            anchors.margins: 16
            spacing: 14

            // Master Header Card
            RowLayout {
                width: parent.width
                implicitHeight: 46
                spacing: 12

                Rectangle {
                    width: 44
                    height: 44
                    implicitHeight: 44
                    implicitWidth: 44
                    radius: 22
                    color: audioPopup.outputAvailable && !audioPopup.outputMuted() ? Colors.color4 : systemPill.cardGlass
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                            easing.type: Easing.OutQuad
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: audioPopup.outputIcon()
                        color: audioPopup.outputAvailable && !audioPopup.outputMuted() ? Colors.background : Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 20
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        width: parent.width
                        text: audioPopup.outputAvailable ? audioPopup.outputName() : "Audio Output"
                        color: Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        text: {
                            if (!audioPopup.outputAvailable)
                                return "No output device";
                            if (audioPopup.outputMuted())
                                return "Muted";
                            return Math.round(audioPopup.outputVolume() * 100) + "% Volume";
                        }
                        color: audioPopup.outputAvailable && !audioPopup.outputMuted() ? Colors.color4 : Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    width: 36
                    height: 36
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    color: audioPopup.outputMuted() ? Qt.rgba(Colors.color1.r, Colors.color1.g, Colors.color1.b, 0.15) : systemPill.cardGlass
                    border.color: audioPopup.outputMuted() ? Colors.color1 : systemPill.borderGlass
                    border.width: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        anchors.centerIn: parent
                        text: audioPopup.outputMuted() ? "󰝟" : "󰕾"
                        color: audioPopup.outputMuted() ? Colors.color1 : Colors.color4
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: audioPopup.outputAvailable
                        onClicked: {
                            let audio = audioPopup.outputAudio;
                            if (audio)
                                audio.muted = !audio.muted;
                        }
                    }
                }
            }

            // Output Volume Slider Section
            Column {
                width: parent.width
                spacing: 6

                RowLayout {
                    width: parent.width
                    Text {
                        text: "Output Volume"
                        color: Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    Text {
                        text: audioPopup.outputMuted() ? "Muted" : (Math.round(audioPopup.outputVolume() * 100) + "%")
                        color: audioPopup.outputMuted() ? Colors.color8 : Colors.color4
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }

                Item {
                    width: parent.width
                    height: 32
                    implicitHeight: 32
                    visible: audioPopup.outputAvailable

                    Rectangle {
                        id: outputTrack
                        x: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 12
                        height: 10
                        radius: 5
                        color: systemPill.cardGlass

                        Rectangle {
                            width: outputTrack.width * audioPopup.outputVolume()
                            height: outputTrack.height
                            radius: 5
                            color: audioPopup.outputMuted() ? Colors.color8 : Colors.color4
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: Colors.foreground
                            border.color: Colors.background
                            border.width: 2
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(outputTrack.width - width, (outputTrack.width * audioPopup.outputVolume()) - width / 2))
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: audioPopup.outputAvailable
                        preventStealing: true

                        function updateVolume(mouseX) {
                            let val = Math.max(0, Math.min(1.0, (mouseX - outputTrack.x) / outputTrack.width));
                            audioPopup.setOutputVolume(val);
                        }

                        onClicked: mouse => updateVolume(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed)
                                updateVolume(mouse.x);
                        }
                        onWheel: wheel => {
                            let audio = audioPopup.outputAudio;
                            if (!audio)
                                return;
                            let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                            audioPopup.setOutputVolume(audio.volume + delta);
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                implicitHeight: 1
                color: systemPill.borderGlass
            }

            // Input (Microphone) Section
            Column {
                width: parent.width
                spacing: 6

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Input (" + audioPopup.inputName() + ")"
                        color: Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: audioPopup.inputMuted() ? "Muted" : (Math.round(audioPopup.inputVolume() * 100) + "%")
                        color: audioPopup.inputMuted() ? Colors.color8 : Colors.color4
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: audioPopup.inputMuted() ? Qt.rgba(Colors.color1.r, Colors.color1.g, Colors.color1.b, 0.15) : systemPill.cardGlass
                        border.color: audioPopup.inputMuted() ? Colors.color1 : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: audioPopup.inputIcon()
                            color: audioPopup.inputMuted() ? Colors.color1 : Colors.color4
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                audioPopup.toggleInputMute();
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 32
                    implicitHeight: 32
                    visible: true

                    Rectangle {
                        id: inputTrack
                        x: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 12
                        height: 10
                        radius: 5
                        color: systemPill.cardGlass

                        Rectangle {
                            width: inputTrack.width * audioPopup.inputVolume()
                            height: inputTrack.height
                            radius: 5
                            color: audioPopup.inputMuted() ? Colors.color8 : Colors.color4
                        }

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: Colors.foreground
                            border.color: Colors.background
                            border.width: 2
                            anchors.verticalCenter: parent.verticalCenter
                            x: Math.max(0, Math.min(inputTrack.width - width, (inputTrack.width * audioPopup.inputVolume()) - width / 2))
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        preventStealing: true

                        function updateVolume(mouseX) {
                            let val = Math.max(0, Math.min(1.0, (mouseX - inputTrack.x) / inputTrack.width));
                            audioPopup.setInputVolume(val);
                        }

                        onClicked: mouse => updateVolume(mouse.x)
                        onPositionChanged: mouse => {
                            if (pressed)
                                updateVolume(mouse.x);
                        }
                        onWheel: wheel => {
                            let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                            audioPopup.setInputVolume(audioPopup.inputVolume() + delta);
                        }
                    }
                }
            }

            // Output Devices Switcher
            Column {
                width: parent.width
                spacing: 6
                visible: audioPopup.sinkNodes.length > 1

                Rectangle {
                    width: parent.width
                    height: 1
                    implicitHeight: 1
                    color: systemPill.borderGlass
                }

                Text {
                    text: "Switch Output Device"
                    color: Colors.color8
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Column {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: audioPopup.sinkNodes

                        delegate: Rectangle {
                            id: sinkItem
                            required property var modelData

                            width: parent.width
                            height: 36
                            implicitHeight: 36
                            radius: 8
                            color: isCurrentSink ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.12) : sinkMouse.containsMouse ? systemPill.cardGlass : "transparent"

                            readonly property bool isCurrentSink: audioPopup.output && audioPopup.output.id === modelData.id

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: isCurrentSink ? "󰄬" : "󰕾"
                                    color: isCurrentSink ? Colors.color4 : Colors.color8
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 13
                                }

                                Text {
                                    text: modelData.description || modelData.nickname || modelData.name || "Output Device"
                                    color: isCurrentSink ? Colors.color4 : Colors.foreground
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 11
                                    font.weight: isCurrentSink ? Font.Bold : Font.Normal
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: sinkMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Pipewire.defaultAudioSink = modelData;
                                }
                            }
                        }
                    }
                }
            }

            // Application Audio Mixer Streams
            Column {
                width: parent.width
                spacing: 8
                visible: audioPopup.mixerStreams.length > 0

                Rectangle {
                    width: parent.width
                    height: 1
                    implicitHeight: 1
                    color: systemPill.borderGlass
                }

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "App Streams"
                        color: Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 22
                        height: 18
                        radius: 9
                        color: systemPill.cardGlass

                        Text {
                            anchors.centerIn: parent
                            text: audioPopup.mixerStreams.length
                            color: Colors.color8
                            font.family: "JetBrainsMono Nerd Font Propo"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: audioPopup.mixerStreams

                        delegate: Item {
                            id: streamItem
                            required property var modelData

                            width: parent.width
                            height: 48
                            implicitHeight: 48

                            property var stream: modelData
                            property var streamAudio: stream && stream.audio ? stream.audio : null

                            RowLayout {
                                width: parent.width
                                height: 22
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: audioPopup.nodeAppName(streamItem.stream)
                                    color: streamItem.streamAudio && !streamItem.streamAudio.muted ? Colors.foreground : Colors.color8
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: streamItem.streamAudio ? (Math.round((Number(streamItem.streamAudio.volume) || 0) * 100) + "%") : "0%"
                                    color: Colors.color8
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 10
                                }

                                Text {
                                    text: streamItem.streamAudio && streamItem.streamAudio.muted ? "󰝟" : "󰕾"
                                    color: streamItem.streamAudio && streamItem.streamAudio.muted ? Colors.color8 : Colors.color4
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 13

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (streamItem.streamAudio) {
                                                streamItem.streamAudio.muted = !streamItem.streamAudio.muted;
                                            }
                                        }
                                    }
                                }
                            }

                            Item {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                height: 20
                                implicitHeight: 20

                                Rectangle {
                                    id: streamTrack
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 6
                                    radius: 3
                                    color: systemPill.cardGlass

                                    Rectangle {
                                        width: streamTrack.width * Math.max(0, Math.min(1.0, streamItem.streamAudio ? Number(streamItem.streamAudio.volume) || 0 : 0))
                                        height: streamTrack.height
                                        radius: 3
                                        color: streamItem.streamAudio && streamItem.streamAudio.muted ? Colors.color8 : Colors.color4
                                    }

                                    Rectangle {
                                        width: 12
                                        height: 12
                                        radius: 6
                                        color: Colors.foreground
                                        anchors.verticalCenter: parent.verticalCenter
                                        x: Math.max(0, Math.min(streamTrack.width - width, (streamTrack.width * (streamItem.streamAudio ? Number(streamItem.streamAudio.volume) || 0 : 0)) - width / 2))
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: streamItem.streamAudio !== null
                                    preventStealing: true

                                    function updateStreamVol(mouseX) {
                                        if (!streamItem.streamAudio)
                                            return;
                                        streamItem.streamAudio.volume = Math.max(0, Math.min(1.0, mouseX / parent.width));
                                    }

                                    onClicked: mouse => updateStreamVol(mouse.x)
                                    onPositionChanged: mouse => {
                                        if (pressed)
                                            updateStreamVol(mouse.x);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: audioPopupComponent
        AudioPopupContent {}
    }
}
