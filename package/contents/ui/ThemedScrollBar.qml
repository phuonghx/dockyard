import QtQuick
import QtQuick.Controls as QQC2

// Even the scrollbar belongs to the palette.
QQC2.ScrollBar {
    id: bar
    policy: QQC2.ScrollBar.AsNeeded
    implicitWidth: Theme.s(8)
    padding: Theme.s(2)
    contentItem: Rectangle {
        implicitWidth: Theme.s(4)
        radius: width / 2
        color: Theme.alpha(Theme.tx, bar.pressed ? 0.45 : (bar.hovered ? 0.32 : 0.2))
        opacity: bar.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.base } }
    }
    background: null
}
