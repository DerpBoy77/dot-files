pragma Singleton
import QtQuick

QtObject {
    // =========================================================
    // Wallust Palette Slots
    // =========================================================

    property color background: "{{background}}"
    property color foreground: "{{foreground}}"
    property color cursor: "{{cursor}}"
    property color color0: "{{color0}}"
    property color color1: "{{color1}}"
    property color color2: "{{color2}}"
    property color color3: "{{color3}}"
    property color color4: "{{color4}}"
    property color color5: "{{color5}}"
    property color color6: "{{color6}}"
    property color color7: "{{color7}}"
    property color color8: "{{color8}}"
    property color color9: "{{color9}}"
    property color color10: "{{color10}}"
    property color color11: "{{color11}}"
    property color color12: "{{color12}}"
    property color color13: "{{color13}}"
    property color color14: "{{color14}}"
    property color color15: "{{color15}}"

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
