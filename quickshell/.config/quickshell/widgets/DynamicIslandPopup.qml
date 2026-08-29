import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../"

PopupWindow {
    id: root

    property var anchorItem: null
    property var anchorWindow: null
    property int anchorEdges: Edges.Top | Edges.Right
    property int anchorGravity: Edges.Bottom | Edges.Left
    property int anchorX: 0
    property int anchorY: 8
    property bool centerHorizontally: false

    property bool popupShown: false
    property bool popupExpanded: false
    property bool contentVisible: false

    property int targetWidth: Theme.popupWidth
    property int targetHeight: Theme.popupDefaultHeight
    property int closedWidth: 32
    property int closedHeight: 32
    property int closedRadius: Theme.pillRadius
    property int expandedRadius: Theme.islandRadius

    property color islandColor: Colors.bgGlass
    property color islandBorderColor: Colors.borderGlass
    property bool grabFocus: true
    property bool autoFocusIsland: true

    property alias islandRect: island
    property alias contentItem: islandContent
    default property alias content: islandContent.data

    signal opened()
    signal closed()

    visible: popupShown
    implicitWidth: Math.max(targetWidth + 20, 380)
    implicitHeight: Math.max(700, island.height + 60)
    color: "transparent"

    anchor {
        item: root.anchorItem
        window: root.anchorWindow
        edges: root.anchorEdges
        gravity: root.anchorGravity
        rect.x: root.centerHorizontally ? (root.anchorWindow !== null ? (root.anchorWindow.width - root.targetWidth) / 2 : 0) : root.anchorX
        rect.y: root.anchorY
    }

    mask: Region {
        item: island
    }

    HyprlandWindow.visibleMask: Region {
        item: island
    }

    onVisibleChanged: {
        if (visible && autoFocusIsland) {
            island.forceActiveFocus();
        }
    }

    Rectangle {
        id: island

        anchors {
            top: parent.top
            right: root.centerHorizontally ? undefined : parent.right
            horizontalCenter: root.centerHorizontally ? parent.horizontalCenter : undefined
        }

        width: root.popupExpanded ? root.targetWidth : root.closedWidth
        height: root.popupExpanded ? root.targetHeight : root.closedHeight
        radius: root.popupExpanded ? root.expandedRadius : root.closedRadius

        color: root.islandColor
        border.color: root.islandBorderColor
        border.width: 1
        clip: true

        focus: true

        Keys.onEscapePressed: {
            root.close();
        }

        Behavior on width {
            NumberAnimation {
                duration: Theme.animIslandWidth
                easing.type: Easing.OutCubic
            }
        }

        Behavior on height {
            NumberAnimation {
                duration: Theme.animIslandHeight
                easing.type: Easing.OutCubic
            }
        }

        Behavior on radius {
            NumberAnimation {
                duration: Theme.animIslandRadius
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: islandContent
            anchors.fill: parent

            opacity: root.popupExpanded && root.contentVisible ? 1 : 0
            scale: root.popupExpanded && root.contentVisible ? 1 : 0.90
            y: root.popupExpanded && root.contentVisible ? 0 : -6
            transformOrigin: root.centerHorizontally ? Item.Center : Item.TopRight

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animContentFade
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.animContentScale
                    easing.type: Easing.OutBack
                    easing.overshoot: Theme.animContentScaleOvershoot
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: Theme.animContentY
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: root.popupShown && root.grabFocus

        onCleared: {
            if (root.popupShown)
                root.close();
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.popupShown
        onActivated: root.close()
    }

    Timer {
        id: closeTimer
        interval: Theme.closeDelay
        repeat: false

        onTriggered: {
            root.popupShown = false;
            root.popupExpanded = false;
            root.contentVisible = false;
            root.closed();
        }
    }

    function open() {
        if (popupExpanded)
            return;
        closeTimer.stop();

        popupShown = true;
        popupExpanded = false;
        contentVisible = false;

        Qt.callLater(function () {
            if (!root.popupShown)
                return;
            root.anchor.updateAnchor();

            Qt.callLater(function () {
                if (!root.popupShown)
                    return;
                root.popupExpanded = true;
                root.contentVisible = true;
                root.opened();
            });
        });
    }

    function close() {
        if (!popupShown)
            return;
        contentVisible = false;
        popupExpanded = false;
        closeTimer.restart();
    }

    function toggle() {
        if (popupShown && popupExpanded) {
            close();
        } else {
            open();
        }
    }
}
