import "../../"

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

Item {
    id: bluetoothPopup

    required property var pill

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
                color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? Colors.color4 : pill.cardGlass

                Text {
                    anchors.centerIn: parent
                    text: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? "󰂯" : "󰂲"
                    color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? Colors.background : Colors.foreground
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 21
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
                color: bluetoothPopup.adapter && bluetoothPopup.adapter.enabled ? Colors.color4 : pill.cardGlass
                Layout.alignment: Qt.AlignVCenter

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
                    onClicked: bluetoothPopup.adapter.enabled = !bluetoothPopup.adapter.enabled
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            implicitHeight: 1
            color: pill.borderGlass
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
                color: scanBtMouse.containsMouse ? pill.cardGlass : "transparent"
                border.color: pill.borderGlass
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
                        if (bluetoothPopup.adapter)
                            bluetoothPopup.adapter.discovering = !bluetoothPopup.adapter.discovering;
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
                    color: deviceMouse.containsMouse ? pill.cardGlass : modelData.connected ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.10) : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 8
                        spacing: 10

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 15
                            color: modelData.connected ? Colors.color4 : pill.cardGlass
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
                            border.color: modelData.connected ? pill.borderGlass : "transparent"
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

        Rectangle {
            width: parent.width
            height: 70
            implicitHeight: 70
            radius: 10
            color: pill.cardGlass
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
