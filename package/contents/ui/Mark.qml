import QtQuick

// The Dockyard mark: six cargo cells on a deck. In the header and the panel icon the
// cells are alive: each one takes the state of a real container (worst first).
Item {
    id: m
    property real size: 28
    property var tones: []
    property color outline: Theme.tx3
    property color deck: Theme.tx3
    width: size; height: size

    readonly property real pad: size * 0.1
    readonly property real gap: size * 0.075
    readonly property real cw: (size - 2 * pad - 2 * gap) / 3
    readonly property real ch: cw * 0.8
    readonly property real deckH: Math.max(1.5, size * 0.085)
    readonly property real groupH: 2 * ch + gap + gap * 1.5 + deckH
    readonly property real oy: (size - groupH) / 2

    Repeater {
        model: 6
        delegate: Rectangle {
            required property int index
            readonly property string tone: index < m.tones.length ? m.tones[index] : ""
            x: m.pad + (index % 3) * (m.cw + m.gap)
            y: m.oy + Math.floor(index / 3) * (m.ch + m.gap)
            width: m.cw; height: m.ch
            radius: m.cw * 0.22
            color: tone === "" || tone === "idle" || tone === "info" || tone === "fail" ? "transparent" : Theme.tone(tone)
            border.width: tone === "run" || tone === "warn" || tone === "bad" ? 0 : Math.max(1.5, m.size * 0.07)
            border.color: tone === "" ? Qt.rgba(m.outline.r, m.outline.g, m.outline.b, 0.7) : (tone === "idle" ? m.outline : Theme.tone(tone))
            Behavior on color { ColorAnimation { duration: Theme.base } }
        }
    }
    Rectangle {
        x: m.pad; y: m.oy + 2 * m.ch + m.gap + m.gap * 1.5
        width: m.size - 2 * m.pad; height: m.deckH; radius: height / 2
        color: m.deck
    }
}
