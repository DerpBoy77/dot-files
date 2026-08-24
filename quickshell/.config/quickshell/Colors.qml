pragma Singleton
import QtQuick

QtObject {
    // =========================================================
    // Wallust Palette Slots
    // =========================================================

    property color background: "#0F1314"
    property color foreground: "#FFE4E0"
    property color cursor: "#859F9F"
    property color color0: "#3A3D3F"
    property color color1: "#3A4C52"
    property color color2: "#417F82"
    property color color3: "#FE4855"
    property color color4: "#49B4B3"
    property color color5: "#FF9552"
    property color color6: "#FFB1A7"
    property color color7: "#F6D0CB"
    property color color8: "#AD918E"
    property color color9: "#3A4C52"
    property color color10: "#417F82"
    property color color11: "#FE4855"
    property color color12: "#49B4B3"
    property color color13: "#FF9552"
    property color color14: "#FFB1A7"
    property color color15: "#F6D0CB"

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
