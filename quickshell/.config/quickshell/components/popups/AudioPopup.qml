import "../../"

import QtQuick
import QtQuick.Layouts

import Quickshell.Services.Pipewire
import Quickshell.Io

Item {
    id: audioPopup

    required property var pill

    implicitWidth: 350
    implicitHeight: audioColumn.implicitHeight + 36

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
            let an = audioPopup.nodeAppName(a).toLowerCase();
            let bn = audioPopup.nodeAppName(b).toLowerCase();
            return an.localeCompare(bn);
        });
        return streams;
    }

    PwObjectTracker {
        objects: [audioPopup.output, audioPopup.input, ...audioPopup.sinkNodes, ...audioPopup.mixerStreams].filter(Boolean)
    }

    readonly property var outputAudio: audioPopup.output && audioPopup.output.audio ? audioPopup.output.audio : null
    readonly property var inputAudio: audioPopup.input && audioPopup.input.audio ? audioPopup.input.audio : null
    readonly property bool outputAvailable: audioPopup.output !== null
    readonly property bool inputAvailable: audioPopup.input !== null

    Process {
        id: wpctlGetSourceProc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = text.trim();
                if (out.startsWith("Volume:")) {
                    let clean = out.replace("Volume:", "").trim();
                    let parts = clean.split(" ");
                    let vol = parseFloat(parts[0]);
                    if (!isNaN(vol)) {
                        audioPopup.fallbackInputVolume = Math.max(0, Math.min(1.0, vol));
                    }
                    audioPopup.fallbackInputMuted = out.includes("[MUTED]");
                }
            }
        }
    }

    Process {
        id: wpctlSetSourceVolProc
        property string targetVol: "1.0"
        command: ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", targetVol]
    }

    Process {
        id: wpctlToggleSourceMuteProc
        command: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"]
    }

    Component.onCompleted: wpctlGetSourceProc.running = true

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

    function outputVolume() {
        let audio = audioPopup.outputAudio;
        if (!audio)
            return 0;
        let volume = Number(audio.volume);
        return isNaN(volume) ? 0 : Math.max(0, Math.min(1.0, volume));
    }

    function inputVolume() {
        let audio = audioPopup.inputAudio;
        if (audio && audio.volume !== undefined && !isNaN(Number(audio.volume))) {
            return Math.max(0, Math.min(1.0, Number(audio.volume)));
        }
        return audioPopup.fallbackInputVolume;
    }

    function outputMuted() {
        return audioPopup.outputAudio ? !!audioPopup.outputAudio.muted : false;
    }
    function inputMuted() {
        if (audioPopup.inputAudio && audioPopup.inputAudio.muted !== undefined)
            return !!audioPopup.inputAudio.muted;
        return audioPopup.fallbackInputMuted;
    }

    function outputIcon() {
        let audio = audioPopup.outputAudio;
        if (!audio)
            return "󰕾";
        if (audio.muted)
            return "󰝟";
        let volume = Number(audio.volume) || 0;
        if (volume <= 0.01)
            return "󰝟";
        if (volume < 0.33)
            return "󰕿";
        if (volume < 0.66)
            return "󰖀";
        return "󰕾";
    }

    function inputIcon() {
        return audioPopup.inputMuted() ? "󰍭" : "󰍬";
    }
    function outputName() {
        return audioPopup.output ? (audioPopup.output.description || audioPopup.output.nickname || audioPopup.output.name || "Speakers") : "No Output";
    }
    function inputName() {
        return audioPopup.input ? (audioPopup.input.description || audioPopup.input.nickname || audioPopup.input.name || "Microphone") : "No Microphone";
    }

    function setOutputVolume(value) {
        let audio = audioPopup.outputAudio;
        if (audio)
            audio.volume = Math.max(0, Math.min(1.0, value));
    }

    function setInputVolume(value) {
        let val = Math.max(0, Math.min(1.0, value));
        audioPopup.fallbackInputVolume = val;
        let audio = audioPopup.inputAudio;
        if (audio)
            audio.volume = val;
        wpctlSetSourceVolProc.targetVol = val.toFixed(2);
        wpctlSetSourceVolProc.running = true;
    }

    function toggleInputMute() {
        let audio = audioPopup.inputAudio;
        if (audio) {
            audio.muted = !audio.muted;
            audioPopup.fallbackInputMuted = audio.muted;
        } else {
            audioPopup.fallbackInputMuted = !audioPopup.fallbackInputMuted;
        }
        wpctlToggleSourceMuteProc.running = true;
    }

    Column {
        id: audioColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        anchors.margins: 16
        spacing: 14

        // Master Header Card
        RowLayout {
            width: parent.width
            implicitHeight: 46
            spacing: 12

            Rectangle {
                width: 44
                height: 44
                radius: 22
                color: audioPopup.outputAvailable && !audioPopup.outputMuted() ? Colors.color4 : pill.cardGlass
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: audioPopup.outputIcon()
                    color: audioPopup.outputAvailable && !audioPopup.outputMuted() ? Colors.background : Colors.foreground
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 20
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    width: parent.width
                    text: audioPopup.outputAvailable ? audioPopup.outputName() : "Audio Output"
                    color: Colors.foreground
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    text: !audioPopup.outputAvailable ? "No output device" : audioPopup.outputMuted() ? "Muted" : Math.round(audioPopup.outputVolume() * 100) + "% Volume"
                    color: audioPopup.outputAvailable && !audioPopup.outputMuted() ? Colors.color4 : Colors.color8
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                }
            }

            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: audioPopup.outputMuted() ? Qt.rgba(Colors.color1.r, Colors.color1.g, Colors.color1.b, 0.15) : pill.cardGlass
                border.color: audioPopup.outputMuted() ? Colors.color1 : pill.borderGlass
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: audioPopup.outputMuted() ? "󰝟" : "󰕾"
                    color: audioPopup.outputMuted() ? Colors.color1 : Colors.color4
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: audioPopup.outputAvailable
                    onClicked: {
                        let audio = audioPopup.outputAudio;
                        if (audio)
                            audio.muted = !audio.muted;
                    }
                }
            }
        }

        // Output Slider
        Column {
            width: parent.width
            spacing: 6

            RowLayout {
                width: parent.width
                Text {
                    text: "Output Volume"
                    color: Colors.color8
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }
                Text {
                    text: audioPopup.outputMuted() ? "Muted" : (Math.round(audioPopup.outputVolume() * 100) + "%")
                    color: audioPopup.outputMuted() ? Colors.color8 : Colors.color4
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }

            Item {
                width: parent.width
                height: 32
                implicitHeight: 32
                visible: audioPopup.outputAvailable

                Rectangle {
                    id: outputTrack
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 12
                    height: 10
                    radius: 5
                    color: pill.cardGlass

                    Rectangle {
                        width: outputTrack.width * audioPopup.outputVolume()
                        height: outputTrack.height
                        radius: 5
                        color: audioPopup.outputMuted() ? Colors.color8 : Colors.color4
                    }

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: Colors.foreground
                        border.color: Colors.background
                        border.width: 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(outputTrack.width - width, (outputTrack.width * audioPopup.outputVolume()) - width / 2))
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: audioPopup.outputAvailable
                    preventStealing: true

                    function updateVolume(mouseX) {
                        let val = Math.max(0, Math.min(1.0, (mouseX - outputTrack.x) / outputTrack.width));
                        audioPopup.setOutputVolume(val);
                    }

                    onClicked: mouse => updateVolume(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            updateVolume(mouse.x);
                    }
                    onWheel: wheel => {
                        let audio = audioPopup.outputAudio;
                        if (!audio)
                            return;
                        audioPopup.setOutputVolume(audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05));
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            implicitHeight: 1
            color: pill.borderGlass
        }

        // Input (Microphone) Slider
        Column {
            width: parent.width
            spacing: 6

            RowLayout {
                width: parent.width
                spacing: 8
                Text {
                    text: "Input (" + audioPopup.inputName() + ")"
                    color: Colors.color8
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: audioPopup.inputMuted() ? "Muted" : (Math.round(audioPopup.inputVolume() * 100) + "%")
                    color: audioPopup.inputMuted() ? Colors.color8 : Colors.color4
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: audioPopup.inputMuted() ? Qt.rgba(Colors.color1.r, Colors.color1.g, Colors.color1.b, 0.15) : pill.cardGlass
                    border.color: audioPopup.inputMuted() ? Colors.color1 : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: audioPopup.inputIcon()
                        color: audioPopup.inputMuted() ? Colors.color1 : Colors.color4
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: audioPopup.toggleInputMute()
                    }
                }
            }

            Item {
                width: parent.width
                height: 32
                implicitHeight: 32
                visible: true

                Rectangle {
                    id: inputTrack
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 12
                    height: 10
                    radius: 5
                    color: pill.cardGlass

                    Rectangle {
                        width: inputTrack.width * audioPopup.inputVolume()
                        height: inputTrack.height
                        radius: 5
                        color: audioPopup.inputMuted() ? Colors.color8 : Colors.color4
                    }

                    Rectangle {
                        width: 18
                        height: 18
                        radius: 9
                        color: Colors.foreground
                        border.color: Colors.background
                        border.width: 2
                        anchors.verticalCenter: parent.verticalCenter
                        x: Math.max(0, Math.min(inputTrack.width - width, (inputTrack.width * audioPopup.inputVolume()) - width / 2))
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    preventStealing: true

                    function updateVolume(mouseX) {
                        let val = Math.max(0, Math.min(1.0, (mouseX - inputTrack.x) / inputTrack.width));
                        audioPopup.setInputVolume(val);
                    }

                    onClicked: mouse => updateVolume(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            updateVolume(mouse.x);
                    }
                    onWheel: wheel => audioPopup.setInputVolume(audioPopup.inputVolume() + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
                }
            }
        }

        // Output Devices Switcher
        Column {
            width: parent.width
            spacing: 6
            visible: audioPopup.sinkNodes.length > 1

            Rectangle {
                width: parent.width
                height: 1
                implicitHeight: 1
                color: pill.borderGlass
            }

            Text {
                text: "Switch Output Device"
                color: Colors.color8
                font.family: "JetBrainsMono Nerd Font Propo"
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: audioPopup.sinkNodes
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 36
                        implicitHeight: 36
                        radius: 8
                        color: isCurrentSink ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.12) : sinkMouse.containsMouse ? pill.cardGlass : "transparent"
                        readonly property bool isCurrentSink: audioPopup.output && audioPopup.output.id === modelData.id

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            Text {
                                text: isCurrentSink ? "󰄬" : "󰕾"
                                color: isCurrentSink ? Colors.color4 : Colors.color8
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 13
                            }
                            Text {
                                text: modelData.description || modelData.nickname || modelData.name || "Output Device"
                                color: isCurrentSink ? Colors.color4 : Colors.foreground
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 11
                                font.weight: isCurrentSink ? Font.Bold : Font.Normal
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Pipewire.defaultAudioSink = modelData
                        }
                    }
                }
            }
        }

        // Mixer Streams
        Column {
            width: parent.width
            spacing: 8
            visible: audioPopup.mixerStreams.length > 0

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
                    text: "App Streams"
                    color: Colors.color8
                    font.family: "JetBrainsMono Nerd Font Propo"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 22
                    height: 18
                    radius: 9
                    color: pill.cardGlass
                    Text {
                        anchors.centerIn: parent
                        text: audioPopup.mixerStreams.length
                        color: Colors.color8
                        font.family: "JetBrainsMono Nerd Font Propo"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 8

                Repeater {
                    model: audioPopup.mixerStreams
                    delegate: Item {
                        id: streamItem
                        required property var modelData
                        width: parent.width
                        height: 48
                        implicitHeight: 48
                        property var stream: modelData
                        property var streamAudio: stream && stream.audio ? stream.audio : null

                        RowLayout {
                            width: parent.width
                            height: 22
                            spacing: 8
                            Text {
                                Layout.fillWidth: true
                                text: audioPopup.nodeAppName(streamItem.stream)
                                color: streamItem.streamAudio && !streamItem.streamAudio.muted ? Colors.foreground : Colors.color8
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }
                            Text {
                                text: streamItem.streamAudio ? (Math.round((Number(streamItem.streamAudio.volume) || 0) * 100) + "%") : "0%"
                                color: Colors.color8
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 10
                            }
                            Text {
                                text: streamItem.streamAudio && streamItem.streamAudio.muted ? "󰝟" : "󰕾"
                                color: streamItem.streamAudio && streamItem.streamAudio.muted ? Colors.color8 : Colors.color4
                                font.family: "JetBrainsMono Nerd Font Propo"
                                font.pixelSize: 13
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (streamItem.streamAudio)
                                            streamItem.streamAudio.muted = !streamItem.streamAudio.muted;
                                    }
                                }
                            }
                        }

                        Item {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: 20
                            implicitHeight: 20

                            Rectangle {
                                id: streamTrack
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: pill.cardGlass

                                Rectangle {
                                    width: streamTrack.width * Math.max(0, Math.min(1.0, streamItem.streamAudio ? Number(streamItem.streamAudio.volume) || 0 : 0))
                                    height: streamTrack.height
                                    radius: 3
                                    color: streamItem.streamAudio && streamItem.streamAudio.muted ? Colors.color8 : Colors.color4
                                }

                                Rectangle {
                                    width: 12
                                    height: 12
                                    radius: 6
                                    color: Colors.foreground
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: Math.max(0, Math.min(streamTrack.width - width, (streamTrack.width * (streamItem.streamAudio ? Number(streamItem.streamAudio.volume) || 0 : 0)) - width / 2))
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: streamItem.streamAudio !== null
                                preventStealing: true
                                function updateStreamVol(mouseX) {
                                    if (!streamItem.streamAudio)
                                        return;
                                    streamItem.streamAudio.volume = Math.max(0, Math.min(1.0, mouseX / parent.width));
                                }
                                onClicked: mouse => updateStreamVol(mouse.x)
                                onPositionChanged: mouse => {
                                    if (pressed)
                                        updateStreamVol(mouse.x);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
