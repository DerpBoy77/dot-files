import "../../"

import QtQuick
import QtQuick.Layouts

import Quickshell.Networking
import Quickshell.Io

Item {
    id: wifiPopup

    required property var pill

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

    property string dynamicIp: "Unknown"
    property string dynamicGw: "Unknown"
    property string dynamicSpeed: "N/A"
    property string dynamicIface: "Unknown"

    Process {
        id: netStatsProc
        command: ["sh", "-c", "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"dev\") {print $(i+1); exit}}'); " + "if [ -z \"$iface\" ]; then iface=$(ip -o link show 2>/dev/null | awk -F': ' '$2 !~ /^lo$/ {print $2; exit}'); fi; " + "ip=$(ip -4 -o addr show dev \"$iface\" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1); " + "if [ -z \"$ip\" ]; then ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"src\") {print $(i+1); exit}}'); fi; " + "gw=$(ip -4 route show default 2>/dev/null | awk 'NR==1 {print $3}'); " + "speed=''; if [ -n \"$iface\" ]; then " + "speed=$(iw dev \"$iface\" link 2>/dev/null | sed -n 's/.*tx bitrate: \\([0-9.]* [^ ]*\\).*/\\1/p' | head -n1); " + "if [ -z \"$speed\" ] && [ -r \"/sys/class/net/$iface/speed\" ]; then " + "raw_speed=$(cat \"/sys/class/net/$iface/speed\" 2>/dev/null); " + "if [ -n \"$raw_speed\" ] && [ \"$raw_speed\" -gt 0 ] 2>/dev/null; then " + "if [ \"$raw_speed\" -ge 1000 ]; then speed=\"$((raw_speed / 1000)) Gbps\"; else speed=\"${raw_speed} Mbps\"; fi; fi; fi; " + "if [ -z \"$speed\" ]; then speed=$(iwconfig \"$iface\" 2>/dev/null | sed -n 's/.*Bit Rate=\\([0-9.]* [^ ]*\\).*/\\1/p' | head -n1); fi; fi; " + "printf '%s|%s|%s|%s' \"${ip:-Unknown}\" \"${gw:-Unknown}\" \"${speed:-N/A}\" \"${iface:-Unknown}\""]

        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split("|");
                if (parts.length >= 4) {
                    wifiPopup.dynamicIp = parts[0] || "Unknown";
                    wifiPopup.dynamicGw = parts[1] || "Unknown";
                    wifiPopup.dynamicSpeed = parts[2] || "N/A";
                    wifiPopup.dynamicIface = parts[3] || "Unknown";
                }
            }
        }
    }

    Component.onCompleted: netStatsProc.running = true

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
                color: Networking.wifiEnabled ? Colors.color4 : pill.cardGlass

                Text {
                    anchors.centerIn: parent
                    text: !Networking.wifiEnabled ? "󰤭" : wifiPopup.connectedWifiNetwork ? wifiPopup.signalIcon(wifiPopup.connectedWifiNetwork.signalStrength) : "󰤭"
                    color: Networking.wifiEnabled ? Colors.background : Colors.foreground
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 21
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
                    text: !Networking.wifiEnabled ? "Off" : wifiPopup.connectedWifiNetwork ? (wifiPopup.connectedWifiNetwork.name || "Connected") : "Not connected"
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
                color: Networking.wifiEnabled ? Colors.color4 : pill.cardGlass
                Layout.alignment: Qt.AlignVCenter

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
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }
        }

        // Quick Stats
        Rectangle {
            width: parent.width
            height: 38
            implicitHeight: 38
            radius: 8
            color: pill.cardGlass
            border.color: pill.borderGlass
            border.width: 1
            visible: Networking.wifiEnabled && (wifiPopup.connectedWifiNetwork !== null)

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                Text {
                    text: "󰩟 " + wifiPopup.dynamicIp
                    color: Colors.foreground
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 10
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: "󰛳 " + wifiPopup.dynamicSpeed
                    color: Colors.color4
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 10
                    font.weight: Font.Medium
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
                            text: wifiPopup.connectedWifiNetwork && wifiPopup.connectedWifiNetwork.stateChanging ? "Connecting…" : (wifiPopup.dynamicGw !== "Unknown" ? ("GW: " + wifiPopup.dynamicGw) : "Active connection")
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
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: wifiPopup.wifiDevice && wifiPopup.wifiDevice.scannerEnabled ? 80 : 62
                    height: 24
                    radius: 6
                    color: scanMouse.containsMouse ? pill.cardGlass : "transparent"
                    border.color: pill.borderGlass
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
                        required property var modelData
                        width: parent.width
                        height: 48
                        implicitHeight: 48
                        radius: 9
                        color: networkMouse.containsMouse ? pill.cardGlass : modelData.connected ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.08) : "transparent"

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
                                border.color: modelData.connected ? pill.borderGlass : "transparent"
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
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 10
                font.weight: Font.Medium

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

    // Ethernet Column (Wired Mode)
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
                color: wifiPopup.ethernetConnected ? Colors.color4 : pill.cardGlass
                Text {
                    anchors.centerIn: parent
                    text: wifiPopup.ethernetConnected ? "󰈀" : "󰈂"
                    color: wifiPopup.ethernetConnected ? Colors.background : Colors.foreground
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 22
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
            color: pill.cardGlass
            border.color: pill.borderGlass
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
                        text: wifiPopup.dynamicIp
                        color: Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 12
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
                    Text {
                        text: "Link Speed"
                        color: Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        Layout.fillWidth: true
                    }
                    Text {
                        text: wifiPopup.dynamicSpeed
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
                    color: pill.borderGlass
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
                        text: wifiPopup.dynamicIface
                        color: Colors.foreground
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
