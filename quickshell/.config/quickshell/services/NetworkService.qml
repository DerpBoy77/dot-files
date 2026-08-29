pragma Singleton
import QtQuick
import Quickshell.Networking
import Quickshell.Io

import "../"

QtObject {
    id: root

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
        let device = wifiDevice;
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

    property var netStatsProc: Process {
        command: ["sh", "-c", "iface=$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"dev\") {print $(i+1); exit}}'); " + "if [ -z \"$iface\" ]; then iface=$(ip -o link show 2>/dev/null | awk -F': ' '$2 !~ /^lo$/ {print $2; exit}'); fi; " + "ip=$(ip -4 -o addr show dev \"$iface\" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1); " + "if [ -z \"$ip\" ]; then ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i==\"src\") {print $(i+1); exit}}'); fi; " + "gw=$(ip -4 route show default 2>/dev/null | awk 'NR==1 {print $3}'); " + "speed=''; " + "phys_iface=\"$iface\"; " + "if [ ! -d \"/sys/class/net/$iface/device\" ]; then " + "phys_iface=$(ls -d /sys/class/net/*/device 2>/dev/null | awk -F'/' '{print $(NF-1)}' | head -n1); " + "fi; " + "phys_iface=\"${phys_iface:-$iface}\"; " + "if [ -n \"$phys_iface\" ]; then " + "speed=$(iw dev \"$phys_iface\" link 2>/dev/null | sed -n 's/.*tx bitrate: \\([0-9.]* [^ ]*\\).*/\\1/p' | head -n1); " + "if [ -z \"$speed\" ] && [ -r \"/sys/class/net/$phys_iface/speed\" ]; then " + "raw_speed=$(cat \"/sys/class/net/$phys_iface/speed\" 2>/dev/null); " + "if [ -n \"$raw_speed\" ] && [ \"$raw_speed\" -gt 0 ] 2>/dev/null; then " + "if [ \"$raw_speed\" -ge 1000 ]; then speed=\"$((raw_speed / 1000)) Gbps\"; else speed=\"${raw_speed} Mbps\"; fi; " + "fi; " + "fi; " + "if [ -z \"$speed\" ]; then " + "eth_speed=$(ethtool \"$phys_iface\" 2>/dev/null | sed -n 's/^[ \t]*Speed: //p'); " + "if [ -n \"$eth_speed\" ] && [ \"$eth_speed\" != \"Unknown!\" ]; then speed=\"$eth_speed\"; fi; " + "fi; " + "if [ -z \"$speed\" ]; then " + "speed=$(iwconfig \"$phys_iface\" 2>/dev/null | sed -n 's/.*Bit Rate=\\([0-9.]* [^ ]*\\).*/\\1/p' | head -n1); " + "fi; " + "fi; " + "printf '%s|%s|%s|%s' \"${ip:-Unknown}\" \"${gw:-Unknown}\" \"${speed:-N/A}\" \"${iface:-Unknown}\""]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = text.trim().split("|");
                if (parts.length >= 4) {
                    root.dynamicIp = parts[0] || "Unknown";
                    root.dynamicGw = parts[1] || "Unknown";
                    root.dynamicSpeed = parts[2] || "N/A";
                    root.dynamicIface = parts[3] || "Unknown";
                }
            }
        }
    }

    function refreshStats() {
        netStatsProc.running = true;
    }

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
        let device = wifiDevice;
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
}
