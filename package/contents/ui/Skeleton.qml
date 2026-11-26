import QtQuick

// Loading placeholder shaped like real rows, so the layout doesn't jump on arrival.
Column {
    id: s
    spacing: Theme.s(2)
    Repeater {
        model: 6
        delegate: Item {
            width: s.width; height: Theme.s(56)
            Rectangle { x: Theme.s(14); anchors.verticalCenter: parent.verticalCenter; width: Theme.s(9); height: width; radius: width / 2; color: Theme.line }
            Column {
                x: Theme.s(36); anchors.verticalCenter: parent.verticalCenter; spacing: Theme.s(7)
                Rectangle { width: Theme.s(120 + (index * 37) % 90); height: Theme.s(11); radius: Theme.s(4); color: Theme.line }
                Rectangle { width: Theme.s(80 + (index * 53) % 80); height: Theme.s(9); radius: Theme.s(4); color: Theme.alpha(Theme.line, 0.6) }
            }
            Rectangle { anchors.right: parent.right; anchors.rightMargin: Theme.s(14); anchors.verticalCenter: parent.verticalCenter; width: Theme.s(54); height: Theme.s(24); radius: Theme.s(7); color: Theme.alpha(Theme.line, 0.6) }
            opacity: 0.6
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                PauseAnimation { duration: index * 90 }
                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.5; duration: 700; easing.type: Easing.InOutSine }
            }
        }
    }
}
