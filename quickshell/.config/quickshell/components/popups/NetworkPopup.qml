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

    implicitWidth: 350
    implicitHeight: wifiPopup.hasWifi ? wifiColumn.implicitHeight + 32 : ethernetColumn.implicitHeight + 32

    Component.onCompleted: NetworkService.refreshStats()

    // =========================================================
    // Wi-Fi Mode
    // =========================================================

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
            visible: Networking.wifiEnabled && (wifiPopup.connectedWifiNetwork !== null)

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
                    width: NetworkService.wifiDevice && NetworkService.wifiDevice.scannerEnabled ? 80 : 62
                    height: 24
                    radius: Theme.smallRadius
                    color: scanMouse.containsMouse ? Colors.cardGlass : "transparent"
                    border.color: Colors.borderGlass
                    border.width: 1
                    Text {
                        anchors.centerIn: parent
                        text: NetworkService.wifiDevice && NetworkService.wifiDevice.scannerEnabled ? "Scanning…" : "Refresh"
                        color: NetworkService.wifiDevice && NetworkService.wifiDevice.scannerEnabled ? Colors.color4 : Colors.foreground
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmall
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
                            }
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 3

                Repeater {
                    model: NetworkService.sortedNetworks()
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 48
                        implicitHeight: 48
                        radius: 9
                        color: networkMouse.containsMouse ? Colors.cardGlass : modelData.connected ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.08) : "transparent"

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

                            Column {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                Text {
                                    width: parent.width
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
                                        visible: modelData.security !== undefined && modelData.security !== WifiSecurityType.Open
                                        text: "• 󰌾"
                                        color: Colors.color8
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSmallest
                                    }
                                }
                            }

                            Rectangle {
                                width: modelData.connected ? 82 : modelData.stateChanging ? 88 : 68
                                height: 28
                                radius: 7
                                Layout.alignment: Qt.AlignVCenter
                                color: networkActionMouse.containsMouse ? (modelData.connected ? Colors.background : Colors.color4) : modelData.connected ? "transparent" : Colors.color4
                                border.color: modelData.connected ? Colors.borderGlass : "transparent"
                                border.width: modelData.connected ? 1 : 0

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.connected ? "Disconnect" : modelData.stateChanging ? "Connecting…" : "Connect"
                                    color: modelData.connected ? Colors.foreground : Colors.background
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Theme.weightMedium
                                }

                                MouseArea {
                                    id: networkActionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !modelData.stateChanging
                                    onClicked: {
                                        if (modelData.connected)
                                            modelData.disconnect();
                                        else
                                            modelData.connect();
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

    // =========================================================
    // Ethernet Mode (Wired)
    // =========================================================

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
                color: wifiPopup.ethernetConnected ? Colors.color4 : Colors.cardGlass
                Text {
                    anchors.centerIn: parent
                    text: wifiPopup.ethernetConnected ? "󰈀" : "󰈂"
                    color: wifiPopup.ethernetConnected ? Colors.background : Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 22
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: "Ethernet"
                    color: Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
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
}
