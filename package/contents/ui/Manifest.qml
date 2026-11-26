import QtQuick
import QtQuick.Controls as QQC2
import "logic.js" as L

// The signature: the fleet drawn as the cargo manifest of a ship, one cell per
// container, coloured by state. Cells keep their place when a state changes,
// and click to jump to that container.
Item {
    id: m
    implicitHeight: Theme.s(14)
    property int count: Backend.ordered.length
    property string highlightId: ""
    signal picked(string cid)
    readonly property real gap: Theme.s(3)
    readonly property real cellW: count > 0 ? Math.max(Theme.s(3), Math.min(Theme.s(34), (width - (count - 1) * gap) / count)) : 0

    Row {
        spacing: m.gap
        Repeater {
            model: m.count
            delegate: Rectangle {
                id: cell
                required property int index
                readonly property var c: { Backend.revision; return Backend.ordered[index] || null }
                readonly property var st: c ? L.statusInfo(c) : ({ tone: "idle", label: "" })
                width: m.cellW
                height: m.height
                radius: Theme.s(3)
                color: st.tone === "idle" ? "transparent" : Theme.tone(st.tone)
                border.width: st.tone === "idle" || st.tone === "info" || st.tone === "fail" ? 1.5 : 0
                border.color: Theme.tone(st.tone)
                opacity: ma.containsMouse ? 1 : (m.highlightId && c && c.id !== m.highlightId ? 0.45 : 0.95)
                scale: ma.containsMouse ? 1.0 : 1.0
                Behavior on color { ColorAnimation { duration: Theme.base } }
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }

                // the one authored moment: the manifest loads in, cell by cell
                transform: Scale { id: sc; origin.y: cell.height; yScale: 1 }
                Component.onCompleted: intro.start()
                SequentialAnimation {
                    id: intro
                    PropertyAction { target: sc; property: "yScale"; value: 0.15 }
                    PauseAnimation { duration: Math.min(index, 40) * 16 }
                    NumberAnimation { target: sc; property: "yScale"; to: 1; duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                }

                MouseArea {
                    id: ma
                    anchors.fill: parent
                    anchors.margins: -m.gap / 2
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (cell.c) m.picked(cell.c.id)
                }
                QQC2.ToolTip.visible: ma.containsMouse && !!cell.c
                QQC2.ToolTip.delay: 150
                QQC2.ToolTip.text: cell.c ? cell.c.name + " · " + cell.st.label : ""
            }
        }
    }
}
