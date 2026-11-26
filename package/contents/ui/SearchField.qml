import QtQuick
import QtQuick.Controls as QQC2

Rectangle {
    id: f
    property alias text: input.text
    property string placeholder: "Search"
    function focusField() { input.forceActiveFocus() }
    implicitHeight: Theme.s(32)
    radius: Theme.s(9)
    color: Theme.inset
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? Theme.acc : Theme.line
    Behavior on border.color { ColorAnimation { duration: Theme.fast } }

    Glyph { id: icon; x: Theme.s(10); anchors.verticalCenter: parent.verticalCenter; name: "search"; size: Theme.s(14); color: input.activeFocus ? Theme.acc : Theme.tx3 }

    TextInput {
        id: input
        anchors { left: icon.right; leftMargin: Theme.s(8); right: clear.left; rightMargin: Theme.s(4); verticalCenter: parent.verticalCenter }
        font.family: Theme.sans
        font.pixelSize: Theme.fs(13)
        color: Theme.tx
        selectionColor: Theme.alpha(Theme.acc, 0.35)
        selectedTextColor: Theme.tx
        clip: true
        selectByMouse: true
        Accessible.name: f.placeholder
        Keys.onEscapePressed: event => { if (text.length) { text = ""; event.accepted = true } else event.accepted = false }
        Txt { anchors.fill: parent; visible: !input.text.length; text: f.placeholder; kind: "body"; color: Theme.tx3; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
    }

    IconButton {
        id: clear
        anchors { right: parent.right; rightMargin: Theme.s(3); verticalCenter: parent.verticalCenter }
        width: Theme.s(24); height: Theme.s(24)
        symbol: "close"; glyphSize: Theme.s(12); tip: "Clear"
        visible: input.text.length > 0
        onClicked: { input.text = ""; input.forceActiveFocus() }
    }
}
