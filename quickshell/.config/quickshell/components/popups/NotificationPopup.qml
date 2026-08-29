import "../../"

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Item {
    id: notifPopup

    required property var pill

    implicitWidth: 360
    implicitHeight: notificationStack.implicitHeight

    // Pause expiration when reading notifications
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onContainsMouseChanged: {
            pill.isNotificationHovered = containsMouse;
        }
    }

    // =========================================================
    // Notification Stack (Uncapped)
    // =========================================================

    Column {
        id: notificationStack

        width: parent.width
        spacing: 0

        Repeater {
            model: pill.activeNotifications

            delegate: Item {
                id: notifEntry

                required property var modelData
                required property int index

                width: notificationStack.width
                implicitHeight: cardColumn.implicitHeight
                height: implicitHeight

                readonly property bool isLastVisible: index === pill.activeNotifications.length - 1
                readonly property real remainingProgress: pill.notificationTick >= 0 ? Math.max(0, Math.min(1, (notifEntry.modelData.expiresAt - Date.now()) / Math.max(1, notifEntry.modelData.timeout))) : 0

                // Card Click Target
                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    z: 0
                    acceptedButtons: Qt.LeftButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (notifEntry.modelData.obj && notifEntry.modelData.obj.actions) {
                            let defaultAct = notifEntry.modelData.obj.actions.find(a => a.id === "default");
                            if (defaultAct)
                                defaultAct.invoke();
                        }
                        pill.dismissNotification(notifEntry.modelData.id);
                    }
                }

                // =================================================
                // Card
                // =================================================

                Column {
                    id: cardColumn
                    width: parent.width
                    spacing: 0
                    z: 1

                    // =============================================
                    // Content
                    // =============================================

                    Item {
                        width: parent.width
                        implicitHeight: notificationContent.implicitHeight + 16
                        height: implicitHeight

                        // Consistent hover treatment matching Clock pill
                        Rectangle {
                            anchors.fill: parent
                            color: cardMouse.containsMouse ? pill.sectionHover : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }

                        RowLayout {
                            id: notificationContent

                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                margins: 10
                            }

                            spacing: 10

                            // Image / App Icon
                            Item {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                Layout.alignment: Qt.AlignTop

                                Image {
                                    id: notificationImage
                                    anchors.fill: parent
                                    source: notifEntry.modelData.image || ""
                                    sourceSize: Qt.size(38, 38)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    smooth: true
                                    visible: false
                                }

                                Rectangle {
                                    id: notificationImageMask
                                    anchors.fill: parent
                                    radius: 8
                                    visible: false
                                }

                                OpacityMask {
                                    anchors.fill: parent
                                    source: notificationImage
                                    maskSource: notificationImageMask
                                    visible: notifEntry.modelData.image !== ""
                                }

                                IconImage {
                                    anchors.fill: parent
                                    source: pill.getNotifIcon(notifEntry.modelData.appIcon, notifEntry.modelData.appName, notifEntry.modelData.desktopEntry)
                                    implicitSize: 32
                                    visible: notifEntry.modelData.image === "" && source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂚"
                                    color: Colors.color4
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 20
                                    visible: notifEntry.modelData.image === "" && pill.getNotifIcon(notifEntry.modelData.appIcon, notifEntry.modelData.appName, notifEntry.modelData.desktopEntry) === ""
                                }
                            }

                            // Notification Text
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: (notifEntry.modelData.appName || "NOTIFICATION").toUpperCase()
                                    color: Colors.color8
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: notifEntry.modelData.summary
                                    visible: text !== ""
                                    color: Colors.foreground
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: notifEntry.modelData.body
                                    visible: text !== ""
                                    color: Colors.foreground
                                    opacity: 0.85
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 11
                                    textFormat: Text.StyledText
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 3
                                    elide: Text.ElideRight
                                }
                            }

                            // Close Button
                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                Layout.alignment: Qt.AlignTop
                                radius: 6
                                color: notifCloseMouse.pressed ? pill.sectionPressed : notifCloseMouse.containsMouse ? pill.sectionHover : "transparent"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 100
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: notifCloseMouse.containsMouse ? Colors.color1 : Colors.color8
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    id: notifCloseMouse
                                    anchors.fill: parent
                                    z: 5
                                    acceptedButtons: Qt.LeftButton
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        pill.dismissNotification(notifEntry.modelData.id);
                                    }
                                }
                            }
                        }
                    }

                    // =============================================
                    // Actions
                    // =============================================

                    Flow {
                        id: notificationActions
                        width: parent.width
                        leftPadding: 10
                        rightPadding: 10
                        bottomPadding: 8
                        spacing: 6
                        visible: notifEntry.modelData.obj && notifEntry.modelData.obj.actions && notifEntry.modelData.obj.actions.length > 0

                        Repeater {
                            model: notifEntry.modelData.obj && notifEntry.modelData.obj.actions ? notifEntry.modelData.obj.actions : []

                            delegate: Rectangle {
                                id: actionButton
                                required property var modelData

                                height: 24
                                width: actionText.implicitWidth + 18
                                radius: 6

                                color: actionMouse.pressed ? Qt.darker(Colors.color4, 1.2) : actionMouse.containsMouse ? Colors.color4 : pill.cardGlass
                                border.color: actionMouse.containsMouse ? Colors.color4 : pill.borderGlass
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 120
                                        easing.type: Easing.OutQuad
                                    }
                                }

                                Text {
                                    id: actionText
                                    anchors.centerIn: parent
                                    text: modelData.text || "Action"
                                    color: actionMouse.containsMouse ? Colors.background : Colors.foreground
                                    font.family: "JetBrainsMono Nerd Font Propo"
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: actionMouse
                                    anchors.fill: parent
                                    z: 10
                                    acceptedButtons: Qt.LeftButton
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        if (modelData)
                                            modelData.invoke();

                                        pill.dismissNotification(notifEntry.modelData.id);
                                    }
                                }
                            }
                        }
                    }

                    // =============================================
                    // Countdown Progress Bar (Inset Track Design)
                    // =============================================

                    Item {
                        width: parent.width
                        height: 6

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                leftMargin: 10
                                rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            height: 2
                            radius: 1
                            color: Qt.rgba(Colors.foreground.r, Colors.foreground.g, Colors.foreground.b, 0.08)

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                }
                                width: parent.width * notifEntry.remainingProgress
                                radius: 1
                                color: notifEntry.modelData.urgency === NotificationUrgency.Critical ? Colors.color1 : Colors.color4

                                Behavior on width {
                                    NumberAnimation {
                                        duration: 40
                                        easing.type: Easing.Linear
                                    }
                                }
                            }
                        }
                    }

                    // =============================================
                    // Separator Between Stacked Notifications
                    // =============================================

                    Rectangle {
                        width: parent.width
                        height: notifEntry.isLastVisible ? 0 : 1
                        color: pill.borderGlass
                        visible: !notifEntry.isLastVisible
                    }
                }
            }
        }
    }
}
