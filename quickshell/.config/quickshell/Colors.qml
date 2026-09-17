pragma Singleton
import QtQuick

QtObject {
    // =========================================================
    // Wallust Palette Slots
    // =========================================================

    property color background: "#242529"
    property color foreground: "#FAFAF9"
    property color cursor: "#B3959F"
    property color color0: "#4E5055"
    property color color1: "#525B6E"
    property color color2: "#8D5E70"
    property color color3: "#7A94AD"
    property color color4: "#B8A5B4"
    property color color5: "#F0B4A2"
    property color color6: "#F2F2ED"
    property color color7: "#F0F0EE"
    property color color8: "#A8A8A6"
    property color color9: "#525B6E"
    property color color10: "#8D5E70"
    property color color11: "#7A94AD"
    property color color12: "#B8A5B4"
    property color color13: "#F0B4A2"
    property color color14: "#F2F2ED"
    property color color15: "#F0F0EE"

    // =========================================================
    // Dynamic Glass Helpers (Consistent with Kitty 0.7 opacity)
    // =========================================================

    // 70% opacity matching Kitty terminal's background_opacity 0.7
    readonly property color bgGlass: Qt.rgba(background.r, background.g, background.b, 0.70)

    // Inner Card / Box Fills (40% opacity of color0)
    readonly property color cardGlass: Qt.rgba(color0.r, color0.g, color0.b, 0.40)

    // Subtle edge borders (16% opacity of foreground)
    readonly property color borderGlass: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)

    // Interactive Overlays
    readonly property color hoverOverlay: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.08)
    readonly property color pressedOverlay: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14)
}
