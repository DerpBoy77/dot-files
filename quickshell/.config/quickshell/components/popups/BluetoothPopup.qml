import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

import "../../"
import "../../services"
import "../../widgets"

Item {
    id: bluetoothPopup

    required property var pill

    readonly property var adapter: BluetoothService.adapter

    implicitWidth: 350
    implicitHeight: bluetoothColumn.implicitHeight + 32

    Column {
        id: bluetoothColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        anchors.margins: 16
        spacing: 14

        // =====================================================
        // Master Header
        // =====================================================

        RowLayout {
            width: parent.width
            spacing: 12

            Rectangle {
                width: 44
                height: 44
                radius: Theme.roundRadius
                color: BluetoothService.powered ? Colors.color4 : Colors.cardGlass

                Text {
                    anchors.centerIn: parent
                    text: BluetoothService.powered ? "󰂯" : "󰂲"
                    color: BluetoothService.powered ? Colors.background : Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeDisplay
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                Text {
                    text: "Bluetooth"
                    color: Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeHeader
                    font.weight: Theme.weightBold
                }
                Row {
                    spacing: 6

                    Spinner {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 12
                        lineWidth: 2
                        color: Colors.color4
                        visible: BluetoothService.powered && BluetoothService.discovering
                        running: visible
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: !bluetoothPopup.adapter ? "Unavailable" : BluetoothService.powered ? (BluetoothService.discovering ? "Discovering…" : "On") : "Off"
                        color: BluetoothService.powered && BluetoothService.discovering ? Colors.color4 : Colors.color8
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeRegular
                    }
                }
            }

            ToggleSwitch {
                Layout.alignment: Qt.AlignVCenter
                checked: BluetoothService.powered
                enabled: bluetoothPopup.adapter !== null
                onToggled: BluetoothService.togglePower()
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            implicitHeight: 1
            color: Colors.borderGlass
        }

        // =====================================================
        // Devices Header & Scan Action
        // =====================================================

        RowLayout {
            width: parent.width
            spacing: 8
            visible: BluetoothService.powered || BluetoothService.sortedDeviceList.length > 0
            Text {
                text: "Devices"
                color: Colors.color8
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeRegular
                font.weight: Theme.weightBold
                Layout.fillWidth: true
            }

            Rectangle {
                width: 60
                height: 24
                radius: Theme.smallRadius
                visible: BluetoothService.powered
                color: scanBtMouse.containsMouse ? Colors.hoverOverlay : "transparent"
                border.color: scanBtMouse.containsMouse ? Colors.color4 : Colors.borderGlass
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animHover } }
                Behavior on border.color { ColorAnimation { duration: Theme.animHover } }

                Spinner {
                    anchors.centerIn: parent
                    size: 13
                    color: Colors.color4
                    visible: BluetoothService.discovering
                    running: visible
                }

                Text {
                    anchors.centerIn: parent
                    visible: !BluetoothService.discovering
                    text: "Scan"
                    color: scanBtMouse.containsMouse ? Colors.color4 : Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
                    Behavior on color { ColorAnimation { duration: Theme.animHover } }
                }

                MouseArea {
                    id: scanBtMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: BluetoothService.toggleDiscovery()
                }
            }
        }

        // =====================================================
        // Devices List
        // =====================================================

        Column {
            width: parent.width
            spacing: 4

            Repeater {
                model: BluetoothService.sortedDeviceList
                delegate: Rectangle {
                    id: deviceRow
                    required property var modelData

                    readonly property bool isDevicePairing: BluetoothService.isPairing(modelData)
                    readonly property bool isDeviceConnecting: modelData.state === BluetoothDeviceState.Connecting
                    readonly property bool isDeviceDisconnecting: modelData.state === BluetoothDeviceState.Disconnecting
                    readonly property bool isDeviceBusy: isDevicePairing || isDeviceConnecting || isDeviceDisconnecting

                    width: parent.width
                    height: 48
                    implicitHeight: 48
                    radius: 9
                    color: deviceMouse.containsMouse ? Colors.cardGlass : modelData.connected ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.10) : "transparent"

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
                                text: BluetoothService.deviceIcon(modelData)
                                color: modelData.connected ? Colors.background : Colors.color8
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
                                text: BluetoothService.deviceName(modelData)
                                color: modelData.connected ? Colors.color4 : Colors.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeBody
                                font.weight: Theme.weightMedium
                                elide: Text.ElideRight
                            }
                            Row {
                                spacing: 6
                                Text {
                                    text: BluetoothService.deviceStatus(modelData)
                                    color: (modelData.connected || deviceRow.isDeviceBusy) ? Colors.color4 : Colors.color8
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                                Text {
                                    visible: modelData.connected && modelData.batteryAvailable
                                    text: "• 󰥉 " + Math.round((modelData.battery || 0) * 100) + "%"
                                    color: Colors.color8
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                            }
                        }

                        RowLayout {
                            id: btButtonContainer
                            spacing: 6
                            Layout.alignment: Qt.AlignVCenter

                            // Individual Device Forget Button
                            Rectangle {
                                id: forgetBtBtn
                                visible: (modelData.paired || modelData.bonded) && !deviceRow.isDeviceBusy
                                width: 28
                                height: 28
                                radius: Theme.itemRadius
                                color: forgetBtMouse.pressed ? Colors.pressedOverlay : forgetBtMouse.containsMouse ? Colors.hoverOverlay : "transparent"
                                border.color: forgetBtMouse.containsMouse ? Colors.color2 : Colors.borderGlass
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                Behavior on border.color { ColorAnimation { duration: Theme.animHover } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰆴"
                                    color: forgetBtMouse.containsMouse ? Colors.color2 : Colors.color8
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                }

                                MouseArea {
                                    id: forgetBtMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: BluetoothService.forgetDevice(modelData)
                                }
                            }

                            // Device Action Button (Pair / Connect / Disconnect)
                            Rectangle {
                                id: deviceAction
                                width: 76
                                height: 28
                                radius: Theme.itemRadius
                                Layout.alignment: Qt.AlignVCenter
                                visible: (modelData.paired || modelData.bonded) || BluetoothService.powered

                                color: {
                                    if (modelData.connected) {
                                        return actionMouse.pressed ? Colors.pressedOverlay : actionMouse.containsMouse ? Colors.hoverOverlay : "transparent";
                                    } else {
                                        if (actionMouse.pressed)
                                            return Qt.darker(Colors.color4, 1.15);
                                        if (actionMouse.containsMouse)
                                            return Qt.lighter(Colors.color4, 1.12);
                                        return Colors.color4;
                                    }
                                }
                                border.color: modelData.connected ? (actionMouse.containsMouse ? Colors.color4 : Colors.borderGlass) : "transparent"
                                border.width: modelData.connected ? 1 : 0

                                Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                Behavior on border.color { ColorAnimation { duration: Theme.animHover } }

                                Spinner {
                                    anchors.centerIn: parent
                                    size: 13
                                    color: modelData.connected ? Colors.color4 : Colors.background
                                    visible: deviceRow.isDeviceBusy
                                    running: visible
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !deviceRow.isDeviceBusy
                                    text: modelData.connected ? "Disconnect" : (modelData.paired || modelData.bonded) ? "Connect" : BluetoothService.powered ? "Pair" : ""
                                    color: modelData.connected ? (actionMouse.containsMouse ? Colors.color4 : Colors.foreground) : Colors.background
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Theme.weightMedium
                                    Behavior on color { ColorAnimation { duration: Theme.animHover } }
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: deviceRow.isDeviceBusy ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    enabled: !deviceRow.isDeviceBusy
                                    onClicked: {
                                        if (modelData.connected)
                                            BluetoothService.disconnectDevice(modelData);
                                        else if (modelData.paired || modelData.bonded)
                                            BluetoothService.connectDevice(modelData);
                                        else if (BluetoothService.powered)
                                            BluetoothService.pairDevice(modelData);
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: deviceMouse
                        anchors.fill: parent
                        anchors.rightMargin: btButtonContainer.width + 16
                        hoverEnabled: true
                        cursorShape: deviceRow.isDeviceBusy ? Qt.ArrowCursor : Qt.PointingHandCursor
                        enabled: !deviceRow.isDeviceBusy
                        onClicked: {
                            if (modelData.connected)
                                BluetoothService.disconnectDevice(modelData);
                            else if (modelData.paired || modelData.bonded)
                                BluetoothService.connectDevice(modelData);
                            else if (BluetoothService.powered)
                                BluetoothService.pairDevice(modelData);
                        }
                    }
                }
            }
        }

        // =====================================================
        // Empty State
        // =====================================================

        Rectangle {
            width: parent.width
            height: 70
            implicitHeight: 70
            radius: 10
            color: Colors.cardGlass
            visible: BluetoothService.sortedDeviceList.length === 0

            Column {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰂲"
                    color: Colors.color8
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: BluetoothService.powered ? "No devices found" : "Bluetooth is off"
                    color: Colors.color8
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                }
            }
        }
    }
}
