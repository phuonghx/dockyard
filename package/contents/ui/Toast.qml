import QtQuick

// Short confirmation / error line. Not a modal: it never takes focus.
Rectangle {
    id: t
    property string tone: "ok"
    property string text: ""
    function show(msg, tn) { text = msg; tone = tn || "ok"; shown = true; hide.restart() }
    property bool shown: false

    height: Theme.s(36)
    width: Math.min(parent.width - Theme.s(32), row.implicitWidth + Theme.s(28))
    radius: Theme.s(10)
    color: Theme.dark ? "#223046" : "#16212f"
    border.width: 1
    border.color: Theme.alpha(Theme.tone(tone === "ok" ? "run" : tone), 0.55)
    opacity: shown ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Theme.base } }
    transform: Translate { y: t.shown ? 0 : Theme.s(10); Behavior on y { NumberAnimation { duration: Theme.base; easing.type: Easing.OutCubic } } }

    Timer { id: hide; interval: 3600; onTriggered: t.shown = false }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.s(8)
        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            name: t.tone === "bad" ? "warning" : "check"
            size: Theme.s(14)
            color: Theme.tone(t.tone === "ok" ? "run" : t.tone)
            weight: 2.2
        }
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, t.parent.width - Theme.s(90))
            text: t.text
            kind: "small"
            color: "#f1f5fa"
            elide: Text.ElideRight
        }
    }
}
