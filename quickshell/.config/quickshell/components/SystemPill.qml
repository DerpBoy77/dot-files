import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import Quickshell.Hyprland

import "../"
import "../services"
import "./popups"

Rectangle {
    id: systemPill

    // =========================================================
    // Dynamic Glass & Palette Helpers
    // =========================================================

    readonly property color bgGlass: Colors.bgGlass
    readonly property color cardGlass: Colors.cardGlass
    readonly property color borderGlass: Colors.borderGlass
    readonly property color sectionHover: Colors.hoverOverlay
    readonly property color sectionPressed: Colors.pressedOverlay

    readonly property int sectionHeight: 24

    // =========================================================
    // Popup State
    // =========================================================

    readonly property int popupNone: 0
    readonly property int popupBluetooth: 1
    readonly property int popupNetwork: 2
    readonly property int popupAudio: 3
    readonly property int popupNotification: 4

    property int popupType: popupNone
    property bool popupShown: false
    property bool popupExpanded: false
    property bool contentVisible: false

    property int popupTargetHeight: Theme.popupDefaultHeight
    readonly property int popupTargetWidth: Theme.popupWidth

    readonly property int tabBarTopMargin: 12
    readonly property int tabBarHeight: Theme.pillHeight
    readonly property int tabBarBottomMargin: 12

    signal popupOpened

    // Reactive listener for incoming & dismissed notifications
    Connections {
        target: NotificationService

        function onNotificationPushed(item) {
            if (systemPill.popupShown && systemPill.popupType === systemPill.popupNotification) {
                systemPill.capturePopupHeight();
                return;
            }

            systemPill.closeTimer.stop();
            systemPill.tabSwitchTimer.stop();

            systemPill.popupType = systemPill.popupNotification;
            systemPill.popupShown = true;
            systemPill.popupExpanded = false;
            systemPill.contentVisible = false;

            Qt.callLater(function () {
                if (!systemPill.popupShown || systemPill.popupType !== systemPill.popupNotification)
                    return;

                dynamicPopup.anchor.updateAnchor();

                Qt.callLater(function () {
                    if (!systemPill.popupShown || systemPill.popupType !== systemPill.popupNotification)
                        return;

                    systemPill.capturePopupHeight();
                    systemPill.popupExpanded = true;
                    systemPill.contentVisible = true;
                    systemPill.popupOpened();
                });
            });
        }

        function onAllDismissed() {
            if (systemPill.popupType === systemPill.popupNotification) {
                systemPill.closePopup();
            }
        }
    }

    // Safety fallback watcher for active notification state
    readonly property bool hasActiveNotification: NotificationService.hasActiveNotification
    onHasActiveNotificationChanged: {
        if (!hasActiveNotification && systemPill.popupType === systemPill.popupNotification && systemPill.popupShown) {
            systemPill.closePopup();
        }
    }

    // =========================================================
    // Popup Height Calculation (Bounded)
    // =========================================================

    function capturePopupHeight() {
        if (!popupContent.item || popupContent.item.implicitHeight <= 0) {
            popupTargetHeight = Theme.popupDefaultHeight;
            return;
        }

        if (popupType === popupNotification) {
            let computed = Math.ceil(33 + popupContent.item.implicitHeight);
            popupTargetHeight = Math.min(800, computed);
            return;
        }

        popupTargetHeight = Math.ceil(systemPill.tabBarTopMargin + systemPill.tabBarHeight + popupContent.item.implicitHeight + systemPill.tabBarBottomMargin);
    }

    // =========================================================
    // Popup Lifecycle
    // =========================================================

    function openPopup(type) {
        trayMenu.close();
        closeTimer.stop();
        tabSwitchTimer.stop();

        popupType = type;
        popupShown = true;
        popupExpanded = false;
        contentVisible = false;

        Qt.callLater(function () {
            if (!systemPill.popupShown)
                return;

            dynamicPopup.anchor.updateAnchor();

            Qt.callLater(function () {
                if (!systemPill.popupShown)
                    return;

                systemPill.capturePopupHeight();
                systemPill.popupExpanded = true;
                systemPill.contentVisible = true;
                systemPill.popupOpened();
            });
        });
    }

    function switchTab(newType) {
        if (popupType === newType && newType !== popupNotification) {
            return;
        }

        contentVisible = false;
        tabSwitchTimer.targetType = newType;
        tabSwitchTimer.restart();
    }

    property var tabSwitchTimer: Timer {
        property int targetType: systemPill.popupNone
        interval: Theme.tabSwitchDelay
        repeat: false

        onTriggered: {
            if (!systemPill.popupShown)
                return;

            systemPill.popupType = targetType;

            Qt.callLater(function () {
                if (!systemPill.popupShown)
                    return;

                systemPill.capturePopupHeight();
                systemPill.contentVisible = true;
            });
        }
    }

    function togglePopup(type) {
        if (popupShown && popupType === type) {
            closePopup();
            return;
        }

        if (popupShown) {
            switchTab(type);
            return;
        }

        openPopup(type);
    }

    function closePopup() {
        if (!popupShown)
            return;

        contentVisible = false;
        popupExpanded = false;
        closeTimer.restart();
    }

    property var closeTimer: Timer {
        interval: Theme.closeDelay
        repeat: false

        onTriggered: {
            systemPill.popupShown = false;
            systemPill.popupExpanded = false;
            systemPill.contentVisible = false;
            systemPill.popupTargetHeight = Theme.popupDefaultHeight;
            systemPill.popupType = systemPill.popupNone;
        }
    }

    // =========================================================
    // Escape
    // =========================================================

    Shortcut {
        sequence: "Escape"
        enabled: systemPill.popupShown || trayMenu.shown

        onActivated: {
            if (trayMenu.shown) {
                trayMenu.close();
                return;
            }

            if (!systemPill.popupShown)
                return;

            if (systemPill.popupType === systemPill.popupNotification) {
                NotificationService.dismissAllNotifications();
            } else {
                systemPill.closePopup();
            }
        }
    }

    // =========================================================
    // Main In-Bar Pill
    // =========================================================

    color: popupShown ? "transparent" : Colors.bgGlass
    radius: Theme.pillRadius
    border.color: popupShown ? "transparent" : Colors.borderGlass
    border.width: popupShown ? 0 : 1
    implicitHeight: Theme.pillHeight
    height: Theme.pillHeight
    implicitWidth: pillRow.implicitWidth + 16
    width: implicitWidth
    Layout.margins: 4
    opacity: popupShown ? 0 : 1

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animPillFade
            easing.type: Easing.OutQuad
        }
    }

    // =========================================================
    // Controls Row Component
    // =========================================================

    component ControlsRow: Row {
        spacing: 2

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
                    radius: Theme.smallRadius
                    color: trayMouse.pressed ? systemPill.sectionPressed : trayMouse.containsMouse ? systemPill.sectionHover : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animHover
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
                                    duration: Theme.animHover
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
                                if (modelData.secondaryActivate) {
                                    modelData.secondaryActivate();
                                } else {
                                    modelData.activate();
                                }
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
                            if (modelData.scroll) {
                                modelData.scroll(wheel.angleDelta.y, false);
                            }
                        }
                    }
                }
            }
        }

        // Bluetooth
        Rectangle {
            id: bluetoothToggle
            implicitWidth: 28
            implicitHeight: systemPill.sectionHeight
            radius: Theme.cardRadius
            anchors.verticalCenter: parent.verticalCenter

            color: bluetoothMouse.pressed ? systemPill.sectionPressed : bluetoothMouse.containsMouse ? systemPill.sectionHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animHover
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: BluetoothService.powered ? "󰂯" : "󰂲"
                color: BluetoothService.powered ? Colors.color4 : Colors.color8
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeHeader
            }

            MouseArea {
                id: bluetoothMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: systemPill.togglePopup(systemPill.popupBluetooth)
            }
        }

        // Network
        Rectangle {
            id: netSection
            implicitWidth: 28
            implicitHeight: systemPill.sectionHeight
            radius: Theme.cardRadius
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool isConnected: (NetworkService.connectedWifiNetwork !== null) || NetworkService.ethernetConnected

            color: networkMouse.pressed ? systemPill.sectionPressed : networkMouse.containsMouse ? systemPill.sectionHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animHover
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: {
                    if (NetworkService.connectedWifiNetwork !== null)
                        return NetworkService.signalIcon(NetworkService.connectedWifiNetwork.signalStrength);
                    if (NetworkService.ethernetConnected)
                        return "󰈀";
                    return NetworkService.hasWifi ? "󰤭" : "󰈂";
                }
                color: netSection.isConnected ? Colors.color4 : Colors.color8
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeHeader
            }

            MouseArea {
                id: networkMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: systemPill.togglePopup(systemPill.popupNetwork)
            }
        }

        // Audio
        Rectangle {
            id: audioSection
            implicitWidth: audioRow.implicitWidth + 8
            implicitHeight: systemPill.sectionHeight
            radius: Theme.cardRadius
            anchors.verticalCenter: parent.verticalCenter

            color: audioMouse.pressed ? systemPill.sectionPressed : audioMouse.containsMouse ? systemPill.sectionHover : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animHover
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
                    text: AudioService.outputIcon
                    color: AudioService.outputMuted ? Colors.color8 : Colors.color4
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeHeader
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(AudioService.outputVolume * 100) + "%"
                    color: Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeBody
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
                    AudioService.toggleOutputMute();
                }

                onWheel: wheel => {
                    let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    AudioService.setOutputVolume(AudioService.outputVolume + delta);
                }
            }
        }
    }

    // In-Bar Row
    ControlsRow {
        id: pillRow
        anchors.centerIn: parent
    }

    TrayContextMenu {
        id: trayMenu
        pill: systemPill
    }

    // =========================================================
    // Dynamic Island Popup
    // =========================================================

    PopupWindow {
        id: dynamicPopup

        implicitWidth: 380
        implicitHeight: Math.max(700, island.height + 60)
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
            if (visible && systemPill.popupType !== systemPill.popupNotification) {
                island.forceActiveFocus();
            }
        }

        Rectangle {
            id: island

            anchors {
                top: parent.top
                right: parent.right
            }

            width: systemPill.popupExpanded ? systemPill.popupTargetWidth : systemPill.width
            height: systemPill.popupExpanded ? systemPill.popupTargetHeight : Theme.pillHeight
            radius: systemPill.popupExpanded ? Theme.islandRadius : Theme.pillRadius

            color: Colors.bgGlass
            border.color: (systemPill.popupType === systemPill.popupNotification && NotificationService.activeNotifications.length > 0 && NotificationService.activeNotifications[0].urgency === NotificationUrgency.Critical) ? Colors.color1 : Colors.borderGlass
            border.width: 1
            clip: true

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animIslandWidth
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: Theme.animIslandHeight
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on radius {
                NumberAnimation {
                    duration: Theme.animIslandRadius
                    easing.type: Easing.OutCubic
                }
            }

            // =================================================
            // Top Bar for Notifications
            // =================================================

            Item {
                id: notifTopBar

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }

                height: Theme.pillHeight
                visible: systemPill.popupType === systemPill.popupNotification

                ControlsRow {
                    anchors {
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                    }
                    height: 1
                    color: Colors.borderGlass
                    opacity: systemPill.popupExpanded ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.animDividerFade
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }

            // =================================================
            // Category Tab Bar
            // =================================================

            Rectangle {
                id: islandTabBar

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: systemPill.tabBarTopMargin
                    leftMargin: 12
                    rightMargin: 12
                }

                height: visible ? systemPill.tabBarHeight : 0
                visible: systemPill.popupType !== systemPill.popupNotification
                radius: Theme.cardRadius
                color: Colors.cardGlass
                border.color: Colors.borderGlass
                border.width: 1
                opacity: systemPill.popupExpanded && visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animDividerFade
                        easing.type: Easing.OutQuad
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 2
                    spacing: 2

                    // Bluetooth Tab
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.smallRadius
                        color: systemPill.popupType === systemPill.popupBluetooth ? Colors.color4 : btTabMouse.containsMouse ? Colors.hoverOverlay : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animHover
                                easing.type: Easing.OutQuad
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "󰂯"
                                color: systemPill.popupType === systemPill.popupBluetooth ? Colors.background : Colors.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeTitle
                            }

                            Text {
                                text: "Bluetooth"
                                color: systemPill.popupType === systemPill.popupBluetooth ? Colors.background : Colors.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeRegular
                                font.weight: systemPill.popupType === systemPill.popupBluetooth ? Theme.weightBold : Theme.weightMedium
                            }
                        }

                        MouseArea {
                            id: btTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: systemPill.togglePopup(systemPill.popupBluetooth)
                        }
                    }

                    // Network Tab
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.smallRadius
                        color: systemPill.popupType === systemPill.popupNetwork ? Colors.color4 : netTabMouse.containsMouse ? Colors.hoverOverlay : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animHover
                                easing.type: Easing.OutQuad
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: NetworkService.hasWifi ? "󰤨" : "󰈀"
                                color: systemPill.popupType === systemPill.popupNetwork ? Colors.background : Colors.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeTitle
                            }

                            Text {
                                text: "Network"
                                color: systemPill.popupType === systemPill.popupNetwork ? Colors.background : Colors.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeRegular
                                font.weight: systemPill.popupType === systemPill.popupNetwork ? Theme.weightBold : Theme.weightMedium
                            }
                        }

                        MouseArea {
                            id: netTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: systemPill.togglePopup(systemPill.popupNetwork)
                        }
                    }

                    // Audio Tab
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.smallRadius
                        color: systemPill.popupType === systemPill.popupAudio ? Colors.color4 : audioTabMouse.containsMouse ? Colors.hoverOverlay : "transparent"

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animHover
                                easing.type: Easing.OutQuad
                            }
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "󰕾"
                                color: systemPill.popupType === systemPill.popupAudio ? Colors.background : Colors.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeTitle
                            }

                            Text {
                                text: "Audio"
                                color: systemPill.popupType === systemPill.popupAudio ? Colors.background : Colors.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeRegular
                                font.weight: systemPill.popupType === systemPill.popupAudio ? Theme.weightBold : Theme.weightMedium
                            }
                        }

                        MouseArea {
                            id: audioTabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: systemPill.togglePopup(systemPill.popupAudio)
                        }
                    }
                }
            }

            // =================================================
            // Dynamic Content Loader
            // =================================================

            Loader {
                id: popupContent

                anchors {
                    top: systemPill.popupType === systemPill.popupNotification ? notifTopBar.bottom : islandTabBar.bottom
                    left: parent.left
                    right: parent.right
                }

                height: item ? item.implicitHeight : 0

                sourceComponent: {
                    if (systemPill.popupType === systemPill.popupBluetooth)
                        return bluetoothPopupComponent;
                    if (systemPill.popupType === systemPill.popupNetwork)
                        return networkPopupComponent;
                    if (systemPill.popupType === systemPill.popupAudio)
                        return audioPopupComponent;
                    if (systemPill.popupType === systemPill.popupNotification)
                        return notificationPopupComponent;
                    return null;
                }

                opacity: systemPill.popupExpanded && systemPill.contentVisible ? 1 : 0
                scale: systemPill.popupExpanded && systemPill.contentVisible ? 1 : 0.90
                y: systemPill.popupExpanded && systemPill.contentVisible ? 0 : -6
                transformOrigin: Item.TopRight

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.animContentFade
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.animContentScale
                        easing.type: Easing.OutBack
                        easing.overshoot: Theme.animContentScaleOvershoot
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: Theme.animContentY
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Connections {
                target: popupContent.item
                function onImplicitHeightChanged() {
                    systemPill.capturePopupHeight();
                }
            }
        }
    }

    // =========================================================
    // Focus Grab
    // =========================================================

    HyprlandFocusGrab {
        id: focusGrab
        windows: [dynamicPopup]
        active: systemPill.popupShown && systemPill.popupType !== systemPill.popupNotification

        onCleared: {
            if (systemPill.popupShown)
                systemPill.closePopup();
        }
    }

    // =========================================================
    // Modular Components
    // =========================================================

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

    Component {
        id: notificationPopupComponent
        NotificationPopup {
            pill: systemPill
        }
    }
}
