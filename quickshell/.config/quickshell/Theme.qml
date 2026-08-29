pragma Singleton
import QtQuick

QtObject {
    // =========================================================
    // Typography
    // =========================================================

    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"

    readonly property int fontSizeSmallest: 9
    readonly property int fontSizeSmall: 10
    readonly property int fontSizeRegular: 11
    readonly property int fontSizeBody: 12
    readonly property int fontSizeTitle: 13
    readonly property int fontSizeSubtitle: 14
    readonly property int fontSizeHeader: 15
    readonly property int fontSizeLarge: 18
    readonly property int fontSizeDisplay: 21

    readonly property int weightNormal: Font.Normal
    readonly property int weightMedium: Font.Medium
    readonly property int weightBold: Font.Bold

    // =========================================================
    // Sizing & Geometry
    // =========================================================

    readonly property int barHeight: 48
    readonly property int pillHeight: 32
    readonly property int pillRadius: 12
    readonly property int islandRadius: 18
    readonly property int cardRadius: 8
    readonly property int itemRadius: 6
    readonly property int smallRadius: 6
    readonly property int roundRadius: 22

    readonly property int popupWidth: 360
    readonly property int popupDefaultHeight: 32

    // =========================================================
    // Animation Presets (Matched to Clock.qml Physics)
    // =========================================================

    // Island Morph Curves
    readonly property int animIslandWidth: 300
    readonly property int animIslandHeight: 340
    readonly property int animIslandRadius: 260

    // Content Spring Pop & Fade
    readonly property int animContentScale: 260
    readonly property real animContentScaleOvershoot: 1.05
    readonly property int animContentY: 280
    readonly property int animContentFade: 150

    // In-Bar Pill & Divider Curves
    readonly property int animPillFade: 90
    readonly property int animDividerWidth: 240
    readonly property int animDividerFade: 140

    // Interactive Widget & Hover Curves
    readonly property int animHover: 120
    readonly property int animButtonScale: 240
    readonly property real animButtonScaleOvershoot: 1.04
    readonly property int animToggle: 220

    // Lifecycle Timers
    readonly property int closeDelay: 350
    readonly property int tabSwitchDelay: 90
}
