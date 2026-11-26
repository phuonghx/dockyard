pragma Singleton
import QtQuick

// Dockyard design tokens.
// World: a harbour master's desk at night. Ink-blue neutrals tinted toward the
// accent hue, one committed accent (lagoon teal) and four state colours that
// only ever appear where they carry meaning.
QtObject {
    id: t

    property string mode: "auto"          // auto | dark | light
    property real sysLightness: 0.1       // fed by main.qml from the Plasma colour scheme
    property real unit: 1                 // UI scale, follows the user's font size
    readonly property bool dark: mode === "dark" || (mode === "auto" && sysLightness < 0.55)

    // surfaces: shell (outer) < surface (list) < raised (hover/selected); inset for fields
    readonly property color shell:   dark ? "#0b1017" : "#e8edf3"
    readonly property color surface: dark ? "#101722" : "#f5f8fb"
    readonly property color raised:  dark ? "#17212f" : "#ffffff"
    readonly property color inset:   dark ? "#0a0e14" : "#e2e9f1"
    readonly property color line:    dark ? "#1c2736" : "#d9e2eb"
    readonly property color lineStrong: dark ? "#2b3a4e" : "#c1cedc"

    // text (all >= 4.5:1 on surface)
    readonly property color tx:  dark ? "#e8eef6" : "#0f1a28"
    readonly property color tx2: dark ? "#a3b3c6" : "#3f5167"
    readonly property color tx3: dark ? "#7789a2" : "#5b6d83"

    // accent + states
    readonly property color acc:    dark ? "#2dd4bf" : "#0b7f74"
    readonly property color accInk: dark ? "#04201c" : "#ffffff"
    readonly property color warn:   dark ? "#f5b544" : "#a86a00"
    readonly property color bad:    dark ? "#ff6b6b" : "#c92f3a"
    readonly property color info:   dark ? "#7c9cff" : "#3d5bd9"
    readonly property color idle:   dark ? "#61748c" : "#7b8ca2"

    readonly property string sans: sansLoader.status === FontLoader.Ready ? sansLoader.name : "Noto Sans"
    readonly property string mono: monoLoader.status === FontLoader.Ready ? monoLoader.name : "monospace"
    property var _sans: FontLoader { id: sansLoader; source: Qt.resolvedUrl("../fonts/Geist.ttf") }
    property var _mono: FontLoader { id: monoLoader; source: Qt.resolvedUrl("../fonts/GeistMono.ttf") }

    function s(n) { return Math.round(n * unit) }
    function fs(n) { return Math.max(9, Math.round(n * unit)) }
    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    function tone(name) {
        switch (name) {
        case "run": case "accent": return acc
        case "warn": return warn
        case "bad": case "fail": case "danger": return bad
        case "info": return info
        default: return idle
        }
    }
    readonly property int fast: 120
    readonly property int base: 200
}
