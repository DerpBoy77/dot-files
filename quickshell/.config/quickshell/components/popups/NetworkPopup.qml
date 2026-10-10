import QtQuick
import QtQuick.Layouts
import Quickshell.Networking

import "../../"
import "../../services"
import "../../widgets"

Item {
    id: wifiPopup

    required property var pill

    readonly property bool hasWifi: NetworkService.hasWifi
    readonly property bool hasEthernet: NetworkService.hasEthernet
    readonly property bool ethernetConnected: NetworkService.ethernetConnected
    readonly property var connectedWifiNetwork: NetworkService.connectedWifiNetwork

    property QtObject activePasswordNetwork: null
    property string enteredPassword: ""
    property string connectionError: ""
    property bool showPassword: false
    property bool isConnecting: false

    function isSecuredNetwork(network) {
        if (!network)
            return false;
        return network.security !== undefined && network.security !== WifiSecurityType.Open;
    }

    function openPasswordPrompt(network) {
        if (activePasswordNetwork === network)
            return;
        activePasswordNetwork = network;
        NetworkService.freezeList = true;
        enteredPassword = "";
        connectionError = "";
        showPassword = false;
        isConnecting = false;
    }

    function resetPasswordPrompt() {
        activePasswordNetwork = null;
        NetworkService.freezeList = false;
        NetworkService.updateNetworkList();
        enteredPassword = "";
        connectionError = "";
        showPassword = false;
        isConnecting = false;
    }

    function submitPassword(network) {
        let target = network || activePasswordNetwork;
        if (!target)
            return;
        if (target.stateChanging)
            return;
        if (!enteredPassword || enteredPassword.length === 0)
            return;
        connectionError = "";
        isConnecting = true;
        try {
            target.connectWithPsk(enteredPassword);
        } catch (e) {
            isConnecting = false;
            connectionError = "Connection error: " + e;
        }
    }

    onVisibleChanged: {
        if (!visible) {
            wifiPopup.resetPasswordPrompt();
        }
    }

    Connections {
        target: Networking
        function onWifiEnabledChanged() {
            if (!Networking.wifiEnabled) {
                wifiPopup.resetPasswordPrompt();
            }
        }
    }

    Connections {
        target: wifiPopup.activePasswordNetwork
        ignoreUnknownSignals: true

        function onConnectionFailed(reason) {
            wifiPopup.isConnecting = false;
            let targetNet = wifiPopup.activePasswordNetwork;
            if (targetNet) {
                try {
                    targetNet.forget();
                } catch (e) {
                    console.warn("Failed to forget network on failure:", e);
                }
            }
            let reasonStr = "";
            try {
                reasonStr = ConnectionFailReason.toString(reason);
            } catch (e) {
                reasonStr = "" + reason;
            }
            if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout) {
                wifiPopup.connectionError = "Authentication failed. Incorrect password.";
            } else if (reasonStr && reasonStr !== "Unknown") {
                wifiPopup.connectionError = "Connection failed: " + reasonStr;
            } else {
                wifiPopup.connectionError = "Connection failed. Please check password.";
            }
        }

        function onConnectedChanged() {
            if (wifiPopup.activePasswordNetwork && wifiPopup.activePasswordNetwork.connected) {
                wifiPopup.resetPasswordPrompt();
            }
        }

        function onStateChangingChanged() {
            if (wifiPopup.activePasswordNetwork && !wifiPopup.activePasswordNetwork.stateChanging) {
                if (wifiPopup.activePasswordNetwork.connected) {
                    wifiPopup.resetPasswordPrompt();
                } else if (wifiPopup.isConnecting) {
                    wifiPopup.isConnecting = false;
                    let targetNet = wifiPopup.activePasswordNetwork;
                    if (targetNet) {
                        try {
                            targetNet.forget();
                        } catch (e) {}
                    }
                    if (!wifiPopup.connectionError) {
                        wifiPopup.connectionError = "Failed to connect. Please check password.";
                    }
                }
            }
        }
    }

    implicitWidth: 350
    implicitHeight: mainColumn.implicitHeight + 32

    Component.onCompleted: NetworkService.refreshStats()

    Column {
        id: mainColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        anchors.margins: 16
        spacing: 14

        // =========================================================
        // Ethernet Section
        // =========================================================

        Column {
            id: ethernetColumn
            width: parent.width
            visible: wifiPopup.ethernetConnected || !wifiPopup.hasWifi
            spacing: 12

            RowLayout {
                width: parent.width
                spacing: 12

                Rectangle {
                    width: 44
                    height: 44
                    radius: Theme.roundRadius
                    color: wifiPopup.ethernetConnected ? Colors.color4 : Colors.cardGlass

                    Text {
                        anchors.centerIn: parent
                        text: wifiPopup.ethernetConnected ? "󰈀" : "󰈂"
                        color: wifiPopup.ethernetConnected ? Colors.background : Colors.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeDisplay
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Ethernet"
                        color: Colors.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeHeader
                        font.weight: Theme.weightBold
                    }

                    Text {
                        text: wifiPopup.ethernetConnected ? "Connected" : "Disconnected"
                        color: wifiPopup.ethernetConnected ? Colors.color4 : Colors.color8
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeRegular
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: ethernetDetailsColumn.implicitHeight + 28
                implicitHeight: ethernetDetailsColumn.implicitHeight + 28
                radius: Theme.pillRadius
                color: Colors.cardGlass
                border.color: Colors.borderGlass
                border.width: 1
                visible: wifiPopup.ethernetConnected

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
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.weightBold
                            Layout.fillWidth: true
                        }
                        Text {
                            text: NetworkService.dynamicIp
                            color: Colors.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        implicitHeight: 1
                        color: Colors.borderGlass
                    }

                    RowLayout {
                        width: parent.width
                        Text {
                            text: "Link Speed"
                            color: Colors.color8
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.weightBold
                            Layout.fillWidth: true
                        }
                        Text {
                            text: NetworkService.dynamicSpeed
                            color: Colors.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                            font.weight: Theme.weightMedium
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        implicitHeight: 1
                        color: Colors.borderGlass
                    }

                    RowLayout {
                        width: parent.width
                        Text {
                            text: "Interface"
                            color: Colors.color8
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Theme.weightBold
                            Layout.fillWidth: true
                        }
                        Text {
                            text: NetworkService.dynamicIface
                            color: Colors.foreground
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeBody
                        }
                    }
                }
            }
        }

        // Section Divider (when both Ethernet and Wi-Fi are visible)
        Rectangle {
            width: parent.width
            height: 1
            implicitHeight: 1
            color: Colors.borderGlass
            visible: ethernetColumn.visible && wifiColumn.visible
        }

        // =========================================================
        // Wi-Fi Section
        // =========================================================

        Column {
            id: wifiColumn
            width: parent.width
            visible: wifiPopup.hasWifi
            spacing: 14

        // Master Header
        RowLayout {
            width: parent.width
            spacing: 12

            Rectangle {
                width: 44
                height: 44
                radius: Theme.roundRadius
                color: Networking.wifiEnabled ? Colors.color4 : Colors.cardGlass

                Text {
                    anchors.centerIn: parent
                    text: !Networking.wifiEnabled ? "󰤭" : wifiPopup.connectedWifiNetwork ? NetworkService.signalIcon(wifiPopup.connectedWifiNetwork.signalStrength) : "󰤭"
                    color: Networking.wifiEnabled ? Colors.background : Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeDisplay
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: "Wi-Fi"
                    color: Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeHeader
                    font.weight: Theme.weightBold
                }
                Text {
                    width: parent.width
                    text: !Networking.wifiEnabled ? "Off" : wifiPopup.connectedWifiNetwork ? (wifiPopup.connectedWifiNetwork.name || "Connected") : "Not connected"
                    color: wifiPopup.connectedWifiNetwork ? Colors.color4 : Colors.color8
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    elide: Text.ElideRight
                }
            }

            ToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: Networking.wifiEnabled
                onToggled: checked => {
                    Networking.wifiEnabled = checked;
                }
            }
        }

        // Quick Stats
        Rectangle {
            width: parent.width
            height: 38
            implicitHeight: 38
            radius: Theme.cardRadius
            color: Colors.cardGlass
            border.color: Colors.borderGlass
            border.width: 1
            visible: Networking.wifiEnabled && (wifiPopup.connectedWifiNetwork !== null) && !wifiPopup.ethernetConnected

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                Text {
                    text: "󰩟 " + NetworkService.dynamicIp
                    color: Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: "󰛳 " + NetworkService.dynamicSpeed
                    color: Colors.color4
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Theme.weightMedium
                }
            }
        }

        // Connected Network Box
        Column {
            width: parent.width
            spacing: 6
            visible: Networking.wifiEnabled && wifiPopup.connectedWifiNetwork !== null

            Text {
                text: "Connected"
                color: Colors.color8
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeRegular
                font.weight: Theme.weightBold
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
                            text: NetworkService.signalIcon(wifiPopup.connectedWifiNetwork ? wifiPopup.connectedWifiNetwork.signalStrength : 1)
                            color: Colors.background
                            font.family: Theme.fontFamily
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
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeTitle
                            font.weight: Theme.weightBold
                            elide: Text.ElideRight
                        }
                        Text {
                            width: parent.width
                            text: wifiPopup.connectedWifiNetwork && wifiPopup.connectedWifiNetwork.stateChanging ? "Connecting…" : (NetworkService.dynamicGw !== "Unknown" ? ("GW: " + NetworkService.dynamicGw) : "Active connection")
                            color: Colors.color8
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSmall
                            elide: Text.ElideRight
                        }
                    }

                    Text {
                        text: "󰄬"
                        color: Colors.color4
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                    }
                }
            }
        }

        // Available Networks List
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
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    font.weight: Theme.weightBold
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 68
                    height: 24
                    radius: Theme.smallRadius
                    color: scanMouse.containsMouse ? Colors.hoverOverlay : "transparent"
                    border.color: scanBtHover ? Colors.color4 : Colors.borderGlass
                    border.width: 1
                    readonly property bool scanBtHover: scanMouse.containsMouse

                    Behavior on color { ColorAnimation { duration: Theme.animHover } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animHover } }

                    Spinner {
                        anchors.centerIn: parent
                        size: 13
                        color: Colors.color4
                        visible: NetworkService.wifiDevice && NetworkService.wifiDevice.scannerEnabled
                        running: visible
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !NetworkService.wifiDevice || !NetworkService.wifiDevice.scannerEnabled
                        text: "Refresh"
                        color: scanMouse.containsMouse ? Colors.color4 : Colors.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
                        Behavior on color { ColorAnimation { duration: Theme.animHover } }
                    }

                    MouseArea {
                        id: scanMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: NetworkService.wifiDevice !== null
                        onClicked: {
                            if (NetworkService.wifiDevice) {
                                NetworkService.wifiDevice.scannerEnabled = !NetworkService.wifiDevice.scannerEnabled;
                                NetworkService.refreshStats();
                                NetworkService.updateNetworkList();
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 3

                Repeater {
                    model: (!Networking.wifiEnabled || !NetworkService.hasWifi) ? [] : NetworkService.networkList
                    delegate: Rectangle {
                        id: networkDelegate
                        required property var modelData

                        readonly property bool isSecured: wifiPopup.isSecuredNetwork(modelData)
                        readonly property bool isExpanded: wifiPopup.activePasswordNetwork === modelData

                        onIsExpandedChanged: {
                            if (isExpanded) {
                                Qt.callLater(function () {
                                    passwordInput.forceActiveFocus();
                                });
                            }
                        }

                        width: parent.width
                        implicitHeight: isExpanded ? 48 + inlinePasswordArea.implicitHeight : 48
                        height: implicitHeight
                        radius: 9
                        color: networkMouse.containsMouse && !isExpanded ? Colors.cardGlass : isExpanded ? Colors.cardGlass : modelData.connected ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.08) : "transparent"
                        border.color: isExpanded ? Colors.borderGlass : "transparent"
                        border.width: isExpanded ? 1 : 0
                        clip: true

                        Behavior on height {
                            NumberAnimation {
                                duration: Theme.animToggle
                                easing.type: Easing.OutCubic
                            }
                        }

                        Column {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                            }

                            // Main Network Row
                            Item {
                                width: parent.width
                                height: 48

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 8
                                    spacing: 10

                                    Rectangle {
                                        width: 30
                                        height: 30
                                        radius: 15
                                        color: modelData.connected ? Colors.color4 : Colors.cardGlass
                                        Layout.alignment: Qt.AlignVCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: NetworkService.signalIcon(modelData.signalStrength)
                                            color: modelData.connected ? Colors.background : NetworkService.signalColor(modelData.signalStrength, modelData.connected)
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeHeader
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 0
                                        Layout.minimumWidth: 0
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.name || "Hidden Network"
                                            color: modelData.connected ? Colors.color4 : Colors.foreground
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeBody
                                            font.weight: modelData.connected ? Theme.weightBold : Theme.weightMedium
                                            elide: Text.ElideRight
                                        }
                                        Row {
                                            spacing: 5
                                            Text {
                                                text: modelData.connected ? "Connected" : modelData.stateChanging ? "Connecting…" : modelData.known ? "Saved" : "Available"
                                                color: modelData.connected ? Colors.color4 : modelData.stateChanging ? Colors.color4 : Colors.color8
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSmallest
                                            }
                                            Text {
                                                visible: networkDelegate.isSecured
                                                text: "• 󰌾"
                                                color: Colors.color8
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSmallest
                                            }
                                        }
                                    }

                                    RowLayout {
                                        id: wifiButtonContainer
                                        spacing: 6
                                        Layout.alignment: Qt.AlignVCenter

                                        // Individual Wi-Fi Forget Button
                                        Rectangle {
                                            id: forgetWifiBtn
                                            visible: modelData.known && !modelData.stateChanging
                                            width: 28
                                            height: 28
                                            radius: Theme.itemRadius
                                            color: forgetWifiMouse.pressed ? Colors.pressedOverlay : forgetWifiMouse.containsMouse ? Colors.hoverOverlay : "transparent"
                                            border.color: forgetWifiMouse.containsMouse ? Colors.color2 : Colors.borderGlass
                                            border.width: 1

                                            Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                            Behavior on border.color { ColorAnimation { duration: Theme.animHover } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰆴"
                                                color: forgetWifiMouse.containsMouse ? Colors.color2 : Colors.color8
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSmall
                                                Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                            }

                                            MouseArea {
                                                id: forgetWifiMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    wifiPopup.resetPasswordPrompt();
                                                    modelData.forget();
                                                }
                                            }
                                        }

                                        // Wi-Fi Action Button (Connect / Disconnect / Spinner)
                                        Rectangle {
                                            id: wifiActionBtn
                                            width: 76
                                            height: 28
                                            radius: Theme.itemRadius
                                            Layout.alignment: Qt.AlignVCenter

                                            color: {
                                                if (modelData.connected) {
                                                    return networkActionMouse.pressed ? Colors.pressedOverlay : networkActionMouse.containsMouse ? Colors.hoverOverlay : "transparent";
                                                } else {
                                                    if (networkActionMouse.pressed)
                                                        return Qt.darker(Colors.color4, 1.15);
                                                    if (networkActionMouse.containsMouse)
                                                        return Qt.lighter(Colors.color4, 1.12);
                                                    return Colors.color4;
                                                }
                                            }
                                            border.color: modelData.connected ? (networkActionMouse.containsMouse ? Colors.color4 : Colors.borderGlass) : "transparent"
                                            border.width: modelData.connected ? 1 : 0

                                            Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                            Behavior on border.color { ColorAnimation { duration: Theme.animHover } }

                                            Spinner {
                                                anchors.centerIn: parent
                                                size: 13
                                                color: modelData.connected ? Colors.color4 : Colors.background
                                                visible: modelData.stateChanging
                                                running: visible
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: !modelData.stateChanging
                                                text: modelData.connected ? "Disconnect" : "Connect"
                                                color: modelData.connected ? (networkActionMouse.containsMouse ? Colors.color4 : Colors.foreground) : Colors.background
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Theme.weightMedium
                                                Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                            }

                                            MouseArea {
                                                id: networkActionMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: modelData.stateChanging ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                enabled: !modelData.stateChanging
                                                onClicked: {
                                                    if (modelData.connected) {
                                                        modelData.disconnect();
                                                    } else if (modelData.known || !networkDelegate.isSecured) {
                                                        wifiPopup.resetPasswordPrompt();
                                                        modelData.connect();
                                                    } else {
                                                        if (networkDelegate.isExpanded) {
                                                            if (wifiPopup.enteredPassword.length > 0) {
                                                                wifiPopup.submitPassword(modelData);
                                                            } else {
                                                                passwordInput.forceActiveFocus();
                                                            }
                                                        } else {
                                                            wifiPopup.openPasswordPrompt(modelData);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: networkMouse
                                    anchors.fill: parent
                                    anchors.rightMargin: wifiButtonContainer.width + 16
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.connected) {
                                            modelData.disconnect();
                                        } else if (modelData.known || !networkDelegate.isSecured) {
                                            wifiPopup.resetPasswordPrompt();
                                            modelData.connect();
                                        } else {
                                            if (!networkDelegate.isExpanded) {
                                                wifiPopup.openPasswordPrompt(modelData);
                                            } else {
                                                passwordInput.forceActiveFocus();
                                            }
                                        }
                                    }
                                }
                            }

                            // Inline Expandable Password Panel
                            Item {
                                id: inlinePasswordArea
                                width: parent.width
                                implicitHeight: networkDelegate.isExpanded ? passwordColumn.implicitHeight + 10 : 0
                                visible: networkDelegate.isExpanded

                                Column {
                                    id: passwordColumn
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        leftMargin: 10
                                        rightMargin: 10
                                    }
                                    spacing: 8

                                    Rectangle {
                                        width: parent.width
                                        height: 32
                                        radius: Theme.smallRadius
                                        color: Colors.background
                                        border.color: wifiPopup.connectionError !== "" ? Colors.color2 : passwordInput.activeFocus ? Colors.color4 : Colors.borderGlass
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 6
                                            spacing: 6

                                            Text {
                                                text: "󰌾"
                                                color: Colors.color8
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSmall
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true

                                                TextInput {
                                                    id: passwordInput
                                                    anchors.fill: parent
                                                    verticalAlignment: TextInput.AlignVCenter
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    color: Colors.foreground
                                                    echoMode: wifiPopup.showPassword ? TextInput.Normal : TextInput.Password
                                                    clip: true
                                                    text: wifiPopup.enteredPassword

                                                    onTextEdited: {
                                                        wifiPopup.enteredPassword = text;
                                                    }

                                                    Keys.onReturnPressed: {
                                                        if (!modelData.stateChanging && wifiPopup.enteredPassword.length > 0)
                                                            wifiPopup.submitPassword(modelData);
                                                    }
                                                    Keys.onEnterPressed: {
                                                        if (!modelData.stateChanging && wifiPopup.enteredPassword.length > 0)
                                                            wifiPopup.submitPassword(modelData);
                                                    }
                                                }

                                                Text {
                                                    anchors.fill: parent
                                                    verticalAlignment: Text.AlignVCenter
                                                    visible: !passwordInput.text && !passwordInput.activeFocus
                                                    text: "Enter password…"
                                                    color: Colors.color8
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeSmall
                                                }
                                            }

                                            // Show / Hide Password Toggle
                                            Rectangle {
                                                width: 22
                                                height: 22
                                                radius: 4
                                                color: eyeMouse.containsMouse ? Colors.hoverOverlay : "transparent"
                                                Layout.alignment: Qt.AlignVCenter

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: wifiPopup.showPassword ? "󰈈" : "󰈉"
                                                    color: wifiPopup.showPassword ? Colors.color4 : Colors.color8
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeSmall
                                                }

                                                MouseArea {
                                                    id: eyeMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: wifiPopup.showPassword = !wifiPopup.showPassword
                                                }
                                            }
                                        }
                                    }

                                    // Connection Failure Feedback
                                    Text {
                                        visible: wifiPopup.connectionError !== ""
                                        width: parent.width
                                        text: wifiPopup.connectionError
                                        color: Colors.color2
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSmallest
                                        wrapMode: Text.WordWrap
                                    }

                                    // Bottom Button Row: Cancel and Connect
                                    RowLayout {
                                        width: parent.width
                                        spacing: 8

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        // Cancel Button
                                        Rectangle {
                                            width: 64
                                            height: 28
                                            radius: Theme.itemRadius
                                            color: cancelMouse.pressed ? Colors.pressedOverlay : cancelMouse.containsMouse ? Colors.hoverOverlay : "transparent"
                                            border.color: cancelMouse.containsMouse ? Colors.color4 : Colors.borderGlass
                                            border.width: 1

                                            Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                            Behavior on border.color { ColorAnimation { duration: Theme.animHover } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Cancel"
                                                color: cancelMouse.containsMouse ? Colors.color4 : Colors.foreground
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Theme.weightMedium
                                                Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                            }

                                            MouseArea {
                                                id: cancelMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: wifiPopup.resetPasswordPrompt()
                                            }
                                        }

                                        // Connect Button
                                        Rectangle {
                                            width: 74
                                            height: 28
                                            radius: Theme.itemRadius
                                            color: {
                                                if (modelData.stateChanging)
                                                    return Colors.color4;
                                                if (wifiPopup.enteredPassword.length === 0)
                                                    return Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.4);
                                                if (inlineConnectMouse.pressed)
                                                    return Qt.darker(Colors.color4, 1.15);
                                                if (inlineConnectMouse.containsMouse)
                                                    return Qt.lighter(Colors.color4, 1.12);
                                                return Colors.color4;
                                            }

                                            Behavior on color { ColorAnimation { duration: Theme.animHover } }

                                            Spinner {
                                                anchors.centerIn: parent
                                                size: 13
                                                color: Colors.background
                                                visible: modelData.stateChanging
                                                running: visible
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                visible: !modelData.stateChanging
                                                text: "Connect"
                                                color: Colors.background
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Theme.weightMedium
                                            }

                                            MouseArea {
                                                id: inlineConnectMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: (wifiPopup.enteredPassword.length > 0 && !modelData.stateChanging) ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                enabled: !modelData.stateChanging && wifiPopup.enteredPassword.length > 0
                                                onClicked: wifiPopup.submitPassword(modelData)
                                            }
                                        }
                                    }
                                }
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
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Theme.weightMedium

                MouseArea {
                    id: forgetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (wifiPopup.connectedWifiNetwork)
                            wifiPopup.connectedWifiNetwork.forget();
                    }
                }
            }
        }
    }
    }
}
