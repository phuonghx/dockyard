import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid

// Language picker, opened from the globe button. Applies instantly and is remembered.
Item {
    id: m
    property bool shown: false
    signal dismissed()
    readonly property string current: Plasmoid.configuration.language

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.fast } }

    MouseArea { anchors.fill: parent; onClicked: m.dismissed() }

    Rectangle {
        anchors { top: parent.top; right: parent.right; topMargin: Theme.s(54); rightMargin: Theme.s(10) }
        width: Theme.s(240)
        height: col.implicitHeight + Theme.s(12)
        radius: Theme.s(12)
        color: Theme.raised
        border.width: 1
        border.color: Theme.lineStrong
        MouseArea { anchors.fill: parent }   // swallow clicks

        Column {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s(6) }
            Repeater {
                model: ["auto"].concat(L10n.codes)
                delegate: QQC2.AbstractButton {
                    id: it
                    required property string modelData
                    readonly property bool on: m.current === modelData
                    width: col.width
                    height: Theme.s(34)
                    hoverEnabled: true
                    Accessible.name: modelData === "auto" ? L10n.t("Automatic (system language)") : L10n.names[modelData]
                    Accessible.checked: on
                    onClicked: { Plasmoid.configuration.language = modelData; m.dismissed() }
                    background: Rectangle {
                        radius: Theme.s(8)
                        color: it.on ? Theme.alpha(Theme.acc, 0.14) : (it.hovered ? Theme.alpha(Theme.tx, 0.07) : "transparent")
                        border.width: it.visualFocus ? 2 : 0
                        border.color: Theme.acc
                        Behavior on color { ColorAnimation { duration: Theme.fast } }
                    }
                    contentItem: Item {
                        Txt {
                            anchors { left: parent.left; leftMargin: Theme.s(10); right: tick.left; rightMargin: Theme.s(6); verticalCenter: parent.verticalCenter }
                            text: it.modelData === "auto" ? L10n.t("Automatic (system language)") : L10n.names[it.modelData]
                            kind: "small"; strong: it.on; elide: Text.ElideRight
                            color: it.on ? Theme.tx : Theme.tx2
                        }
                        Glyph { id: tick; anchors { right: parent.right; rightMargin: Theme.s(10); verticalCenter: parent.verticalCenter }
                            name: "check"; size: Theme.s(14); color: Theme.acc; weight: 2.2; visible: it.on }
                    }
                }
            }
        }
    }
}
