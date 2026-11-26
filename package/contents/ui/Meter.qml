import QtQuick

// Label + value over a thin bar. Used for per-container CPU and memory.
Item {
    id: m
    property string label: ""
    property string value: ""
    property real fraction: 0
    property string tone: "run"
    implicitHeight: col.implicitHeight
    Column {
        id: col
        width: parent.width
        spacing: Theme.s(5)
        Item {
            width: parent.width; height: lbl.implicitHeight
            Txt { id: lbl; text: m.label; kind: "tiny"; color: Theme.tx3 }
            Txt { anchors.right: parent.right; text: m.value; kind: "monoSm"; color: Theme.tx }
        }
        Rectangle {
            width: parent.width; height: Theme.s(4); radius: height / 2
            color: Theme.alpha(Theme.tx, 0.09)
            Rectangle {
                width: Math.max(parent.height, parent.width * Math.min(1, m.fraction)); height: parent.height; radius: height / 2
                color: m.fraction > 0.85 ? Theme.bad : (m.fraction > 0.65 ? Theme.warn : Theme.tone(m.tone))
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }
    }
}
