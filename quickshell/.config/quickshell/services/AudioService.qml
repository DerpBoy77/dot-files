pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io

QtObject {
    id: root

    // =========================================================
    // Signals & Initialization
    // =========================================================

    signal volumeChanged(real volume, bool muted)
    property bool isInitialized: false

    property var initTimer: Timer {
        interval: 1200
        repeat: false
        running: true
        onTriggered: root.isInitialized = true
    }

    // =========================================================
    // PipeWire Handles
    // =========================================================

    readonly property var output: Pipewire.defaultAudioSink
    readonly property var input: Pipewire.defaultAudioSource

    property real fallbackInputVolume: 1.0
    property bool fallbackInputMuted: false

    readonly property var sinkNodes: {
        if (!Pipewire.nodes)
            return [];
        let list = [];
        for (let node of Pipewire.nodes.values) {
            if (!node || node.isStream || !node.isSink || !node.audio)
                continue;
            list.push(node);
        }
        return list;
    }

    readonly property var mixerStreams: {
        if (!Pipewire.nodes)
            return [];
        let streams = [];
        for (let node of Pipewire.nodes.values) {
            if (!node || !node.isStream || !node.isSink || !node.audio)
                continue;
            streams.push(node);
        }
        streams.sort((a, b) => {
            let an = root.nodeAppName(a).toLowerCase();
            let bn = root.nodeAppName(b).toLowerCase();
            return an.localeCompare(bn);
        });
        return streams;
    }

    // Assigned to a property so QtObject accepts it
    property var tracker: PwObjectTracker {
        objects: [root.output, root.input, ...root.sinkNodes, ...root.mixerStreams].filter(Boolean)
    }

    readonly property var outputAudio: root.output && root.output.audio ? root.output.audio : null
    readonly property var inputAudio: root.input && root.input.audio ? root.input.audio : null
    readonly property bool outputAvailable: root.output !== null
    readonly property bool inputAvailable: root.input !== null

    // Reactive Volume Getters
    readonly property real outputVolume: {
        if (!outputAudio)
            return 0;
        let vol = Number(outputAudio.volume);
        return isNaN(vol) ? 0 : Math.max(0, Math.min(1.0, vol));
    }

    readonly property bool outputMuted: outputAudio ? !!outputAudio.muted : false

    readonly property real inputVolume: {
        if (inputAudio && inputAudio.volume !== undefined && !isNaN(Number(inputAudio.volume))) {
            return Math.max(0, Math.min(1.0, Number(inputAudio.volume)));
        }
        return root.fallbackInputVolume;
    }

    readonly property bool inputMuted: {
        if (inputAudio && inputAudio.muted !== undefined)
            return !!inputAudio.muted;
        return root.fallbackInputMuted;
    }

    // Trigger OSD on Volume / Mute change
    onOutputVolumeChanged: {
        if (isInitialized)
            root.volumeChanged(outputVolume, outputMuted);
    }

    onOutputMutedChanged: {
        if (isInitialized)
            root.volumeChanged(outputVolume, outputMuted);
    }

    // =========================================================
    // Icons & Labels
    // =========================================================

    readonly property string outputIcon: {
        if (!outputAudio)
            return "󰕾";
        if (outputMuted)
            return "󰝟";
        if (outputVolume <= 0.01)
            return "󰝟";
        if (outputVolume < 0.33)
            return "󰕿";
        if (outputVolume < 0.66)
            return "󰖀";
        return "󰕾";
    }

    readonly property string inputIcon: inputMuted ? "󰍭" : "󰍬"

    function nodeAppName(node) {
        if (!node)
            return "Unknown Application";
        let props = node.properties;
        if (props) {
            if (props["application.name"])
                return props["application.name"];
            if (props["media.name"])
                return props["media.name"];
            if (props["node.description"])
                return props["node.description"];
        }
        return (node.description || node.nickname || node.name || "Unknown Application");
    }

    // =========================================================
    // WPCTL Fallbacks & Setters (Assigned to properties)
    // =========================================================

    property var wpctlGetSourceProc: Process {
        id: wpctlGetSourceProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out.startsWith("Volume:")) {
                    let clean = out.replace("Volume:", "").trim();
                    let parts = clean.split(" ");
                    let vol = parseFloat(parts[0]);
                    if (!isNaN(vol))
                        root.fallbackInputVolume = Math.max(0, Math.min(1.0, vol));
                    root.fallbackInputMuted = out.includes("[MUTED]");
                }
            }
        }
    }

    property var wpctlSetSourceVolProc: Process {
        id: wpctlSetSourceVolProc
        property string targetVol: "1.0"
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", targetVol]
    }

    property var wpctlToggleSourceMuteProc: Process {
        id: wpctlToggleSourceMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }

    function setOutputVolume(val) {
        if (outputAudio)
            outputAudio.volume = Math.max(0, Math.min(1.0, val));
    }

    function setInputVolume(val) {
        let clamped = Math.max(0, Math.min(1.0, val));
        root.fallbackInputVolume = clamped;
        if (inputAudio)
            inputAudio.volume = clamped;
        wpctlSetSourceVolProc.targetVol = clamped.toFixed(2);
        wpctlSetSourceVolProc.running = true;
    }

    function toggleInputMute() {
        if (inputAudio) {
            inputAudio.muted = !inputAudio.muted;
            root.fallbackInputMuted = inputAudio.muted;
        } else {
            root.fallbackInputMuted = !root.fallbackInputMuted;
        }
        wpctlToggleSourceMuteProc.running = true;
    }

    function toggleOutputMute() {
        if (outputAudio) {
            outputAudio.muted = !outputAudio.muted;
        }
    }
}
