pragma Singleton
import QtQuick
import Quickshell.Bluetooth

QtObject {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property bool discovering: adapter !== null && adapter.discovering

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

    readonly property var sortedDeviceList: {
        if (!Bluetooth.devices)
            return [];
        return sortedDevices();
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

    function togglePower() {
        if (adapter) {
            adapter.enabled = !adapter.enabled;
        }
    }

    function toggleDiscovery() {
        if (adapter) {
            adapter.discovering = !adapter.discovering;
        }
    }
}
