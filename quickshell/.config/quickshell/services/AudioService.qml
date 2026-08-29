pragma Singleton
import QtQuick
import Quickshell.Services.Pipewire
import Quickshell.Io

QtObject {
    id: root

    readonly property var output: Pipewire.defaultAudioSink
    readonly property var input: Pipewire.defaultAudioSource

    property real fallbackInputVolume: 1.0
    property bool fallbackInputMuted: false

    readonly property var outputAudio: output && output.audio ? output.audio : null
    readonly property var inputAudio: input && input.audio ? input.audio : null
    readonly property bool outputAvailable: output !== null
    readonly property bool inputAvailable: input !== null

    // =========================================================
    // Reactive Properties
    // =========================================================

    readonly property real outputVolume: {
        if (!outputAudio || outputAudio.volume === undefined)
            return 0;
        let volume = Number(outputAudio.volume);
        return isNaN(volume) ? 0 : Math.max(0, Math.min(1.0, volume));
    }

    readonly property real inputVolume: {
        if (inputAudio && inputAudio.volume !== undefined && !isNaN(Number(inputAudio.volume))) {
            return Math.max(0, Math.min(1.0, Number(inputAudio.volume)));
        }
        return fallbackInputVolume;
    }

    readonly property bool outputMuted: outputAudio ? !!outputAudio.muted : false

    readonly property bool inputMuted: {
        if (inputAudio && inputAudio.muted !== undefined)
            return !!inputAudio.muted;
        return fallbackInputMuted;
    }

    readonly property string outputIcon: {
        if (!outputAudio)
            return "󰕾";
        if (outputAudio.muted)
            return "󰝟";
        let vol = root.outputVolume;
        if (vol <= 0.01)
            return "󰝟";
        if (vol < 0.33)
            return "󰕿";
        if (vol < 0.66)
            return "󰖀";
        return "󰕾";
    }

    readonly property string inputIcon: root.inputMuted ? "󰍭" : "󰍬"

    readonly property string outputName: output ? (output.description || output.nickname || output.name || "Speakers") : "No Output"

    readonly property string inputName: input ? (input.description || input.nickname || input.name || "Microphone") : "No Microphone"

    // =========================================================
    // Node Tracking
    // =========================================================

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

    property var tracker: PwObjectTracker {
        objects: [root.output, root.input, ...root.sinkNodes, ...root.mixerStreams].filter(Boolean)
    }

    // =========================================================
    // Fallback Shell Processes
    // =========================================================

    property var wpctlGetSourceProc: Process {
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out.startsWith("Volume:")) {
                    let clean = out.replace("Volume:", "").trim();
                    let parts = clean.split(" ");
                    let vol = parseFloat(parts[0]);
                    if (!isNaN(vol)) {
                        root.fallbackInputVolume = Math.max(0, Math.min(1.0, vol));
                    }
                    root.fallbackInputMuted = out.includes("[MUTED]");
                }
            }
        }
    }

    property var wpctlSetSourceVolProc: Process {
        property string targetVol: "1.0"
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", targetVol]
    }

    property var wpctlToggleSourceMuteProc: Process {
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }

    function refreshInputState() {
        wpctlGetSourceProc.running = true;
    }

    function nodeAppName(node) {
        if (!node)
            return "Unknown Application";
        let properties = node.properties;
        if (properties) {
            if (properties["application.name"])
                return properties["application.name"];
            if (properties["media.name"])
                return properties["media.name"];
            if (properties["node.description"])
                return properties["node.description"];
        }
        return (node.description || node.nickname || node.name || "Unknown Application");
    }

    function setOutputVolume(value) {
        let audio = outputAudio;
        if (audio)
            audio.volume = Math.max(0, Math.min(1.0, value));
    }

    function setInputVolume(value) {
        let val = Math.max(0, Math.min(1.0, value));
        fallbackInputVolume = val;
        let audio = inputAudio;
        if (audio)
            audio.volume = val;
        wpctlSetSourceVolProc.targetVol = val.toFixed(2);
        wpctlSetSourceVolProc.running = true;
    }

    function toggleOutputMute() {
        let audio = outputAudio;
        if (audio)
            audio.muted = !audio.muted;
    }

    function toggleInputMute() {
        let audio = inputAudio;
        if (audio) {
            audio.muted = !audio.muted;
            fallbackInputMuted = audio.muted;
        } else {
            fallbackInputMuted = !fallbackInputMuted;
        }
        wpctlToggleSourceMuteProc.running = true;
    }

    function setDefaultSink(node) {
        if (node) {
            Pipewire.defaultAudioSink = node;
        }
    }
}
