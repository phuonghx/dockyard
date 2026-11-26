import QtQuick
import QtQuick.Controls as QQC2

// A compose project. Collapses, and acts on every container in it at once.
QQC2.AbstractButton {
    id: h
    required property string rid
    required property string label
    required property int count
    required property int running
    required property bool collapsed
    signal toggled(string group)
    readonly property string title: label !== "" ? label : L10n.t("Standalone")

    width: ListView.view ? ListView.view.width : 400
    height: Theme.s(34)
    hoverEnabled: true
    onClicked: toggled(rid)
    Accessible.name: title + ", " + L10n.t("%1/%2 running", running, count)

    readonly property var members: { Backend.revision; return Backend.containers.filter(c => (c.project || "") === h.rid) }

    Item {
        anchors { fill: parent; leftMargin: Theme.s(14); rightMargin: Theme.s(10) }

        Glyph {
            id: chev
            anchors.verticalCenter: parent.verticalCenter
            name: "chevronRight"; size: Theme.s(13); color: Theme.tx3
            rotation: h.collapsed ? 0 : 90
            Behavior on rotation { NumberAnimation { duration: Theme.base; easing.type: Easing.OutCubic } }
        }
        Glyph {
            id: folder
            anchors { left: chev.right; leftMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
            name: h.rid === "" ? "box" : "layers"; size: Theme.s(14); color: h.running > 0 ? Theme.acc : Theme.tx3
        }
        Txt {
            id: title
            anchors { left: folder.right; leftMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
            text: h.title; kind: "small"; strong: true; color: Theme.tx2
        }
        Txt {
            anchors { left: title.right; leftMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
            text: L10n.t("%1/%2 running", h.running, h.count); kind: "tiny"; color: Theme.tx3; tnum: true
        }
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: Theme.s(2)
            opacity: (h.hovered || startBtn.visualFocus || restartBtn.visualFocus || stopBtn.visualFocus) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Theme.fast } }
            IconButton { id: startBtn; symbol: "play"; tip: L10n.t("Start all"); width: Theme.s(26); height: width; glyphSize: Theme.s(13)
                visible: h.running < h.count; onClicked: Backend.act("start", h.members.filter(c => c.state !== "running").map(c => c.id)) }
            IconButton { id: restartBtn; symbol: "restart"; tip: L10n.t("Restart all"); width: Theme.s(26); height: width; glyphSize: Theme.s(13)
                visible: h.running > 0; onClicked: Backend.act("restart", h.members.filter(c => c.state === "running").map(c => c.id)) }
            IconButton { id: stopBtn; symbol: "stop"; tip: L10n.t("Stop all"); width: Theme.s(26); height: width; glyphSize: Theme.s(13)
                visible: h.running > 0; onClicked: Backend.act("stop", h.members.filter(c => c.state === "running").map(c => c.id)) }
        }
    }
    background: Rectangle { color: h.hovered ? Theme.alpha(Theme.tx, 0.04) : "transparent"; Behavior on color { ColorAnimation { duration: Theme.fast } } }
}
