import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

import "../../"

PopupWindow {
    id: root

    required property var pill

    property var activeMenuHandle: null
    property var anchorItem: null
    property bool shown: false
    property bool expanded: false

    function open(menuHandle, item) {
        if (!menuHandle)
            return;
        closeTimer.stop();
        pill.closePopup();

        activeMenuHandle = menuHandle;
        anchorItem = item;
        shown = true;
        expanded = false;

        Qt.callLater(function () {
            if (!root.shown)
                return;
            root.anchor.updateAnchor();
            Qt.callLater(function () {
                if (root.shown)
                    root.expanded = true;
            });
        });
    }

    function close() {
        if (!shown)
            return;
        expanded = false;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 180
        repeat: false
        onTriggered: {
            root.shown = false;
            root.activeMenuHandle = null;
            root.anchorItem = null;
        }
    }

    function resolveMenuIcon(iconName) {
        if (!iconName || iconName === "")
            return "";
        if (iconName.startsWith("/") || iconName.startsWith("file://"))
            return iconName;
        let rawName = iconName.replace(/^image:\/\/icon\//, "").split("?")[0];
        if (Quickshell.hasThemeIcon(rawName))
            return Quickshell.iconPath(rawName, true);
        return "";
    }

    visible: root.shown && root.anchorItem !== null
    implicitWidth: menuCard.implicitWidth + 24
    implicitHeight: menuCard.implicitHeight + 24
    color: "transparent"

    anchor {
        item: root.anchorItem || pill
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
    }

    onVisibleChanged: {
        if (visible)
            anchor.updateAnchor();
        else if (root.shown)
            root.close();
    }

    QsMenuOpener {
        id: trayOpener
        menu: root.activeMenuHandle
    }

    Rectangle {
        id: menuCard
        anchors {
            top: parent.top
            right: parent.right
        }
        implicitWidth: Math.max(160, menuItemsColumn.implicitWidth + 16)
        implicitHeight: menuItemsColumn.implicitHeight + 16
        radius: Theme.pillRadius
        color: Colors.bgGlass
        border.color: Colors.borderGlass
        border.width: 1
        clip: true

        transformOrigin: Item.TopRight

        opacity: root.expanded ? 1 : 0
        scale: root.expanded ? 1 : 0.90
        y: root.expanded ? 0 : -6

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animContentFade
                easing.type: Easing.OutQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.animButtonScale
                easing.type: Easing.OutBack
                easing.overshoot: Theme.animButtonScaleOvershoot
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: Theme.animButtonScale
                easing.type: Easing.OutCubic
            }
        }

        Column {
            id: menuItemsColumn
            anchors.centerIn: parent
            width: parent.implicitWidth - 16
            spacing: 3

            Repeater {
                model: trayOpener.children

                delegate: Item {
                    id: menuItemDelegate
                    required property var modelData

                    width: menuItemsColumn.width
                    height: modelData.isSeparator ? 9 : 28
                    implicitHeight: height

                    Rectangle {
                        visible: menuItemDelegate.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width
                        height: 1
                        color: Colors.borderGlass
                    }

                    Rectangle {
                        visible: !menuItemDelegate.modelData.isSeparator
                        anchors.fill: parent
                        radius: Theme.itemRadius
                        color: itemMouse.containsMouse ? Colors.cardGlass : "transparent"
                        opacity: menuItemDelegate.modelData.enabled !== false ? 1 : 0.65

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.animHover
                                easing.type: Easing.OutQuad
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                visible: menuItemDelegate.modelData.checkState !== undefined && menuItemDelegate.modelData.checkState !== Qt.Unchecked
                                text: "󰄬"
                                color: Colors.color4
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeRegular
                            }

                            Item {
                                id: iconWrapper
                                width: 14
                                height: 14
                                visible: iconSource.resolved !== ""

                                Image {
                                    id: iconSource
                                    property string resolved: root.resolveMenuIcon(menuItemDelegate.modelData.icon)
                                    anchors.fill: parent
                                    source: resolved
                                    sourceSize: Qt.size(16, 16)
                                    visible: false
                                }

                                ColorOverlay {
                                    anchors.fill: parent
                                    source: iconSource
                                    color: itemMouse.containsMouse ? Colors.color4 : Colors.foreground
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.animHover
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (menuItemDelegate.modelData.text || "").replace(/_([a-zA-Z0-9])/g, "$1")
                                color: itemMouse.containsMouse ? Colors.color4 : Colors.foreground
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeRegular
                                font.weight: Theme.weightMedium
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: menuItemDelegate.modelData.hasChildren
                                text: "󰅂"
                                color: Colors.color8
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSmall
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: menuItemDelegate.modelData.enabled !== false

                            onClicked: {
                                root.close();
                                menuItemDelegate.modelData.triggered();
                            }
                        }
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        id: menuFocusGrab
        windows: [root]
        active: root.shown
        onCleared: root.close()
    }
}
