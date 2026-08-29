import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

import "../../"
import "../../services"
import "../../widgets"

Item {
    id: audioPopup

    required property var pill

    implicitWidth: 350
    implicitHeight: audioColumn.implicitHeight + 36

    Column {
        id: audioColumn
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        anchors.margins: 16
        spacing: 14

        // =====================================================
        // Master Header Card
        // =====================================================

        RowLayout {
            width: parent.width
            implicitHeight: 46
            spacing: 12

            Rectangle {
                width: 44
                height: 44
                radius: Theme.roundRadius
                color: AudioService.outputAvailable && !AudioService.outputMuted() ? Colors.color4 : Colors.cardGlass
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: AudioService.outputIcon()
                    color: AudioService.outputAvailable && !AudioService.outputMuted() ? Colors.background : Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                }
            }

            Column {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter

                Text {
                    width: parent.width
                    text: AudioService.outputAvailable ? AudioService.outputName() : "Audio Output"
                    color: Colors.foreground
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSubtitle
                    font.weight: Theme.weightBold
                    elide: Text.ElideRight
                }

                Text {
                    text: !AudioService.outputAvailable ? "No output device" : AudioService.outputMuted() ? "Muted" : Math.round(AudioService.outputVolume() * 100) + "% Volume"
                    color: AudioService.outputAvailable && !AudioService.outputMuted() ? Colors.color4 : Colors.color8
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                }
            }

            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: AudioService.outputMuted() ? Qt.rgba(Colors.color1.r, Colors.color1.g, Colors.color1.b, 0.15) : Colors.cardGlass
                border.color: AudioService.outputMuted() ? Colors.color1 : Colors.borderGlass
                border.width: 1
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: AudioService.outputMuted() ? "󰝟" : "󰕾"
                    color: AudioService.outputMuted() ? Colors.color1 : Colors.color4
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    enabled: AudioService.outputAvailable
                    onClicked: AudioService.toggleOutputMute()
                }
            }
        }

        // =====================================================
        // Output Slider
        // =====================================================

        Column {
            width: parent.width
            spacing: 6

            RowLayout {
                width: parent.width
                Text {
                    text: "Output Volume"
                    color: Colors.color8
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    font.weight: Theme.weightBold
                    Layout.fillWidth: true
                }
                Text {
                    text: AudioService.outputMuted() ? "Muted" : (Math.round(AudioService.outputVolume() * 100) + "%")
                    color: AudioService.outputMuted() ? Colors.color8 : Colors.color4
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    font.weight: Theme.weightBold
                }
            }

            SliderTrack {
                width: parent.width
                value: AudioService.outputVolume()
                muted: AudioService.outputMuted()
                enabled: AudioService.outputAvailable
                onMoved: val => AudioService.setOutputVolume(val)
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            implicitHeight: 1
            color: Colors.borderGlass
        }

        // =====================================================
        // Input (Microphone) Slider
        // =====================================================

        Column {
            width: parent.width
            spacing: 6

            RowLayout {
                width: parent.width
                spacing: 8
                Text {
                    text: "Input (" + AudioService.inputName() + ")"
                    color: Colors.color8
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    font.weight: Theme.weightBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: AudioService.inputMuted() ? "Muted" : (Math.round(AudioService.inputVolume() * 100) + "%")
                    color: AudioService.inputMuted() ? Colors.color8 : Colors.color4
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    font.weight: Theme.weightBold
                }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: AudioService.inputMuted() ? Qt.rgba(Colors.color1.r, Colors.color1.g, Colors.color1.b, 0.15) : Colors.cardGlass
                    border.color: AudioService.inputMuted() ? Colors.color1 : "transparent"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: AudioService.inputIcon()
                        color: AudioService.inputMuted() ? Colors.color1 : Colors.color4
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeBody
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: AudioService.toggleInputMute()
                    }
                }
            }

            SliderTrack {
                width: parent.width
                value: AudioService.inputVolume()
                muted: AudioService.inputMuted()
                enabled: true
                onMoved: val => AudioService.setInputVolume(val)
            }
        }

        // =====================================================
        // Output Devices Switcher
        // =====================================================

        Column {
            width: parent.width
            spacing: 6
            visible: AudioService.sinkNodes.length > 1

            Rectangle {
                width: parent.width
                height: 1
                implicitHeight: 1
                color: Colors.borderGlass
            }

            Text {
                text: "Switch Output Device"
                color: Colors.color8
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeRegular
                font.weight: Theme.weightBold
            }

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: AudioService.sinkNodes
                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        height: 36
                        implicitHeight: 36
                        radius: Theme.cardRadius
                        color: isCurrentSink ? Qt.rgba(Colors.color4.r, Colors.color4.g, Colors.color4.b, 0.12) : sinkMouse.containsMouse ? Colors.cardGlass : "transparent"
                        readonly property bool isCurrentSink: AudioService.output && AudioService.output.id === modelData.id

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            Text {
                                text: isCurrentSink ? "󰄬" : "󰕾"
                                color: isCurrentSink ? Colors.color4 : Colors.color8
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeTitle
                            }
                            Text {
                                text: modelData.description || modelData.nickname || modelData.name || "Output Device"
                                color: isCurrentSink ? Colors.color4 : Colors.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeRegular
                                font.weight: isCurrentSink ? Theme.weightBold : Theme.weightNormal
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        MouseArea {
                            id: sinkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: AudioService.setDefaultSink(modelData)
                        }
                    }
                }
            }
        }

        // =====================================================
        // Mixer Streams
        // =====================================================

        Column {
            width: parent.width
            spacing: 8
            visible: AudioService.mixerStreams.length > 0

            Rectangle {
                width: parent.width
                height: 1
                implicitHeight: 1
                color: Colors.borderGlass
            }

            RowLayout {
                width: parent.width
                spacing: 8
                Text {
                    text: "App Streams"
                    color: Colors.color8
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeRegular
                    font.weight: Theme.weightBold
                    Layout.fillWidth: true
                }
                Rectangle {
                    width: 22
                    height: 18
                    radius: 9
                    color: Colors.cardGlass
                    Text {
                        anchors.centerIn: parent
                        text: AudioService.mixerStreams.length
                        color: Colors.color8
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSmallest
                        font.weight: Theme.weightBold
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 8

                Repeater {
                    model: AudioService.mixerStreams
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
                                text: AudioService.nodeAppName(streamItem.stream)
                                color: streamItem.streamAudio && !streamItem.streamAudio.muted ? Colors.foreground : Colors.color8
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeRegular
                                font.weight: Theme.weightMedium
                                elide: Text.ElideRight
                            }
                            Text {
                                text: streamItem.streamAudio ? (Math.round((Number(streamItem.streamAudio.volume) || 0) * 100) + "%") : "0%"
                                color: Colors.color8
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                            }
                            Text {
                                text: streamItem.streamAudio && streamItem.streamAudio.muted ? "󰝟" : "󰕾"
                                color: streamItem.streamAudio && streamItem.streamAudio.muted ? Colors.color8 : Colors.color4
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeTitle
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

                        SliderTrack {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            height: 20
                            trackHeight: 6
                            thumbSize: 12
                            value: streamItem.streamAudio ? (Number(streamItem.streamAudio.volume) || 0) : 0
                            muted: streamItem.streamAudio ? !!streamItem.streamAudio.muted : false
                            enabled: streamItem.streamAudio !== null
                            onMoved: val => {
                                if (streamItem.streamAudio)
                                    streamItem.streamAudio.volume = Math.max(0, Math.min(1.0, val));
                            }
                        }
                    }
                }
            }
        }
    }
}
