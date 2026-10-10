pragma Singleton
import QtQuick
import Quickshell.Bluetooth
import Quickshell.Io

QtObject {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property bool discovering: adapter !== null && adapter.discovering

    property var pairingMap: ({})

    function isPairing(device) {
        if (!device)
            return false;
        let devKey = device.dbusPath || device.address || "";
        return (device.pairing === true) || (devKey !== "" && !!pairingMap[devKey]);
    }

    function pairDevice(device) {
        if (!device || !device.address)
            return;

        let mac = device.address;
        let devKey = device.dbusPath || mac;

        let map = Object.assign({}, pairingMap);
        map[devKey] = true;
        pairingMap = map;

        let cmd = "printf 'default-agent\\npair " + mac + "\\ntrust " + mac + "\\n' | bluetoothctl; sleep 1; printf 'connect " + mac + "\\n' | bluetoothctl";
        let proc = Qt.createQmlObject("import QtQuick; import Quickshell.Io; Process { command: ['sh', '-c', " + JSON.stringify(cmd) + "]; running: true; }", root, "pairProc_" + mac.replace(/[^a-zA-Z0-9]/g, "_"));

        let cleanup = null;
        let onDone = null;
        let timeoutTimer = null;
        let finished = false;

        cleanup = function () {
            if (finished)
                return;
            finished = true;
            let m = Object.assign({}, pairingMap);
            delete m[devKey];
            pairingMap = m;
            if (proc) {
                try { proc.destroy(); } catch (e) {}
                proc = null;
            }
            try { device.connectedChanged.disconnect(onDone); } catch (e) {}
            try { device.pairedChanged.disconnect(onDone); } catch (e) {}
            try { device.pairingChanged.disconnect(onDone); } catch (e) {}
            if (timeoutTimer) {
                try { timeoutTimer.stop(); timeoutTimer.destroy(); } catch (e) {}
                timeoutTimer = null;
            }
            cleanup = null;
        };

        onDone = function () {
            if (device.connected && (device.paired || device.bonded) && !device.pairing) {
                device.trusted = true;
                if (cleanup)
                    cleanup();
            } else if ((device.paired || device.bonded) && !device.pairing && !device.connected) {
                device.trusted = true;
                root.connectDevice(device);
            }
        };

        timeoutTimer = Qt.createQmlObject("import QtQuick; Timer { interval: 30000; repeat: false; }", root, "pairTimer_" + mac.replace(/[^a-zA-Z0-9]/g, "_"));
        timeoutTimer.triggered.connect(function () {
            if (cleanup)
                cleanup();
        });
        timeoutTimer.start();

        try {
            device.connectedChanged.connect(onDone);
            device.pairedChanged.connect(onDone);
            device.pairingChanged.connect(onDone);
        } catch (e) {}
    }

    function connectDevice(device) {
        if (!device)
            return;
        if (!powered && adapter) {
            adapter.enabled = true;
        }
        let mac = device.address;
        if (mac) {
            let cmd = (!powered ? "sleep 0.5; " : "") + "printf 'connect " + mac + "\\n' | bluetoothctl";
            Qt.createQmlObject("import QtQuick; import Quickshell.Io; Process { command: ['sh', '-c', " + JSON.stringify(cmd) + "]; running: true; }", root, "connProc_" + mac.replace(/[^a-zA-Z0-9]/g, "_"));
        } else {
            try { device.connect(); } catch (e) {}
        }
    }

    function disconnectDevice(device) {
        if (!device)
            return;
        let mac = device.address;
        if (mac) {
            let cmd = "printf 'disconnect " + mac + "\\n' | bluetoothctl";
            Qt.createQmlObject("import QtQuick; import Quickshell.Io; Process { command: ['sh', '-c', " + JSON.stringify(cmd) + "]; running: true; }", root, "disconnProc_" + mac.replace(/[^a-zA-Z0-9]/g, "_"));
        } else {
            try { device.disconnect(); } catch (e) {}
        }
    }

    function forgetDevice(device) {
        if (!device)
            return;
        let mac = device.address;
        let devKey = device.dbusPath || mac || "";
        if (devKey && pairingMap[devKey]) {
            let map = Object.assign({}, pairingMap);
            delete map[devKey];
            pairingMap = map;
        }
        try {
            device.forget();
        } catch (e) {}
        if (mac) {
            let cmd = "printf 'remove " + mac + "\\n' | bluetoothctl";
            Qt.createQmlObject("import QtQuick; import Quickshell.Io; Process { command: ['sh', '-c', " + JSON.stringify(cmd) + "]; running: true; }", root, "forgetProc_" + mac.replace(/[^a-zA-Z0-9]/g, "_"));
        }
    }

    function deviceName(device) {
        if (!device)
            return "Unknown Device";
        return device.name || device.deviceName || device.alias || device.address || "Unknown Device";
    }

    function deviceStatus(device) {
        if (!device)
            return "Unknown";
        if (device.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (device.connected)
            return "Connected";
        if (device.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (isPairing(device))
            return "Pairing…";
        if (device.paired || device.bonded)
            return "Paired";
        return "Available";
    }

    function sortedDevices() {
        if (!Bluetooth.devices)
            return [];
        let devices = Bluetooth.devices.values.slice();
        if (!powered) {
            devices = devices.filter(d => d && (d.paired || d.bonded));
        }
        devices.sort((a, b) => {
            if (a.connected && !b.connected)
                return -1;
            if (!a.connected && b.connected)
                return 1;
            if (isPairing(a) && !isPairing(b))
                return -1;
            if (!isPairing(a) && isPairing(b))
                return 1;
            let aPaired = a.paired || a.bonded;
            let bPaired = b.paired || b.bonded;
            if (aPaired && !bPaired)
                return -1;
            if (!aPaired && bPaired)
                return 1;
            return ((a.name || "").localeCompare(b.name || ""));
        });
        return devices.slice(0, 10);
    }

    readonly property var sortedDeviceList: {
        let _p = root.powered;
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
