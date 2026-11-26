import QtQuick
import QtQuick.Controls as QQC2

// Small pill. With 'clickable' it behaves as a button (ports, filters).
QQC2.AbstractButton {
    id: c
    property string tone: "neutral"       // neutral | accent | run | warn | bad | info
    property bool mono: false
    property bool selected: false
    property bool clickable: false
    property string tip: ""
    property alias glyph: g.name

    implicitHeight: Theme.s(20)
    implicitWidth: row.implicitWidth + Theme.s(14)
    hoverEnabled: clickable
    focusPolicy: clickable ? Qt.TabFocus : Qt.NoFocus
    Accessible.name: text

    readonly property color col: tone === "neutral" ? Theme.tx2 : Theme.tone(tone)

    background: Rectangle {
        radius: height / 2
        color: c.selected ? Theme.alpha(c.tone === "neutral" ? Theme.tx : c.col, 0.16)
             : (c.hovered ? Theme.alpha(Theme.tx, 0.10) : Theme.alpha(c.tone === "neutral" ? Theme.tx : c.col, 0.08))
        border.width: c.visualFocus ? 2 : (c.selected ? 1 : 0)
        border.color: c.visualFocus ? Theme.acc : Theme.alpha(c.col, 0.5)
        Behavior on color { ColorAnimation { duration: Theme.fast } }
    }
    contentItem: Row {
        id: row
        spacing: Theme.s(4)
        Glyph { id: g; anchors.verticalCenter: parent.verticalCenter; size: Theme.s(11); color: c.col; visible: name.length > 0; weight: 2 }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            text: c.text
            kind: c.mono ? "monoSm" : "tiny"
            strong: !c.mono
            color: c.col
        }
    }
    QQC2.ToolTip.visible: hovered && tip.length > 0
    QQC2.ToolTip.delay: 450
    QQC2.ToolTip.text: tip
}
