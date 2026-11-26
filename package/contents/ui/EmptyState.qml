import QtQuick
import QtQuick.Layouts

Item {
    id: e
    property string icon: "box"
    property string title: ""
    property string body: ""
    property string tone: "neutral"
    default property alias actions: actionRow.data

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Theme.s(48), Theme.s(320))
        spacing: Theme.s(10)

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: Theme.s(48); height: width; radius: Theme.s(14)
            color: e.tone === "neutral" ? Theme.raised : Theme.alpha(Theme.tone(e.tone), 0.12)
            border.width: 1
            border.color: e.tone === "neutral" ? Theme.line : Theme.alpha(Theme.tone(e.tone), 0.4)
            Glyph { anchors.centerIn: parent; name: e.icon; size: Theme.s(22); color: e.tone === "neutral" ? Theme.tx2 : Theme.tone(e.tone) }
        }
        Txt { Layout.alignment: Qt.AlignHCenter; Layout.topMargin: Theme.s(4); text: e.title; kind: "head"; strong: true }
        Txt {
            Layout.fillWidth: true
            visible: text.length > 0
            horizontalAlignment: Text.AlignHCenter
            text: e.body; kind: "small"; color: Theme.tx2; wrapMode: Text.WordWrap
        }
        Row { id: actionRow; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: Theme.s(6); spacing: Theme.s(8) }
    }
}
