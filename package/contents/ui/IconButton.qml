import QtQuick
import QtQuick.Controls as QQC2

QQC2.AbstractButton {
    id: b
    property string symbol: ""
    property string label: ""
    property string tone: "neutral"       // neutral | accent | danger
    property bool solid: false            // primary filled button
    property bool busy: false
    property bool armed: false            // second-click confirmation state
    property real glyphSize: Theme.s(15)
    property string tip: ""

    implicitHeight: Theme.s(28)
    implicitWidth: label.length ? contentRow.implicitWidth + Theme.s(18) : Theme.s(28)
    hoverEnabled: true
    focusPolicy: Qt.TabFocus
    Accessible.role: Accessible.Button
    Accessible.name: label.length ? label : tip

    readonly property color fg: {
        if (!enabled) return Theme.tx3
        if (solid) return Theme.accInk
        if (armed) return Theme.bad
        if (tone === "accent") return Theme.acc
        if (tone === "danger") return (hovered || visualFocus) ? Theme.bad : Theme.tx2
        return (hovered || visualFocus || down) ? Theme.tx : Theme.tx2
    }

    background: Rectangle {
        radius: Theme.s(7)
        color: {
            if (b.solid) return b.down ? Qt.darker(Theme.acc, 1.15) : (b.hovered ? Qt.lighter(Theme.acc, 1.1) : Theme.acc)
            if (b.armed) return Theme.alpha(Theme.bad, 0.16)
            if (b.down) return Theme.alpha(Theme.tx, 0.14)
            if (b.hovered) return b.tone === "accent" ? Theme.alpha(Theme.acc, 0.16) : Theme.alpha(Theme.tx, 0.09)
            return b.tone === "accent" && b.label.length ? Theme.alpha(Theme.acc, 0.10) : "transparent"
        }
        border.width: b.visualFocus ? 2 : (b.label.length && !b.solid ? 1 : 0)
        border.color: b.visualFocus ? Theme.acc : Theme.line
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }

    contentItem: Item {
        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: Theme.s(6)
            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                name: b.symbol
                size: b.glyphSize
                filled: b.symbol === "play" || b.symbol === "stop"
                color: b.fg
                visible: b.symbol.length > 0
                RotationAnimator on rotation { running: b.busy; from: 0; to: 360; duration: 900; loops: Animation.Infinite }
                Behavior on color { ColorAnimation { duration: Theme.fast } }
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                visible: b.label.length > 0
                text: b.label
                kind: "small"
                strong: true
                color: b.fg
            }
        }
    }

    QQC2.ToolTip.visible: hovered && tip.length > 0 && !down
    QQC2.ToolTip.delay: 450
    QQC2.ToolTip.text: tip

    scale: down ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 90 } }
}
