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
                Text {
                    text: !bluetoothPopup.adapter ? "Unavailable" : BluetoothService.powered ? (BluetoothService.discovering ? "Scanning…" : "On") : "Off"
                    color: BluetoothService.powered && BluetoothService.discovering ? Colors.color4 : Colors.color8
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
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
            Text {
                text: "Devices"
                color: Colors.color8
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeRegular
                font.weight: Theme.weightBold
                Layout.fillWidth: true
            }

            Rectangle {
                width: BluetoothService.discovering ? 76 : 60
                height: 24
                radius: Theme.smallRadius
                visible: BluetoothService.powered
                color: scanBtMouse.containsMouse ? Colors.cardGlass : "transparent"
                border.color: Colors.borderGlass
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: BluetoothService.discovering ? "Scanning…" : "Scan"
                    color: BluetoothService.discovering ? Colors.color4 : Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSmall
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

                        Column {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            Text {
                                width: parent.width
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
                                    color: modelData.connected ? Colors.color4 : Colors.color8
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

                        Rectangle {
                            id: deviceAction
                            width: modelData.connected ? 82 : modelData.paired ? 68 : 54
                            height: 28
                            radius: 7
                            color: actionMouse.containsMouse ? (modelData.connected ? Colors.background : Colors.color4) : modelData.connected ? "transparent" : Colors.color4
                            border.color: modelData.connected ? Colors.borderGlass : "transparent"
                            border.width: modelData.connected ? 1 : 0
                            Layout.alignment: Qt.AlignVCenter

                            Text {
                                anchors.centerIn: parent
                                text: modelData.connected ? "Disconnect" : modelData.pairing ? "Pairing…" : modelData.paired ? "Connect" : "Pair"
                                color: modelData.connected ? Colors.foreground : Colors.background
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Theme.weightMedium
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !modelData.pairing
                                onClicked: {
                                    if (modelData.connected)
                                        modelData.disconnect();
                                    else if (modelData.paired)
                                        modelData.connect();
                                    else
                                        modelData.pair();
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

        // =====================================================
        // Empty State
        // =====================================================

        Rectangle {
            width: parent.width
            height: 70
            implicitHeight: 70
            radius: 10
            color: Colors.cardGlass
            visible: !Bluetooth.devices || Bluetooth.devices.values.length === 0

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
