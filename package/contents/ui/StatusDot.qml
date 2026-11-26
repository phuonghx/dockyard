import QtQuick

// State is never colour alone: each tone also has its own silhouette.
//   run = filled circle   info = pulsing ring   warn = rounded square
//   bad = filled diamond  fail = hollow diamond idle = hollow circle
Item {
    id: d
    property string tone: "idle"
    property real size: Theme.s(10)
    width: size; height: size
    readonly property color c: Theme.tone(tone)

    Rectangle {
        anchors.centerIn: parent
        width: d.size * (d.tone === "bad" || d.tone === "fail" ? 0.74 : 1)
        height: width
        rotation: d.tone === "bad" || d.tone === "fail" ? 45 : 0
        radius: d.tone === "warn" ? width * 0.28 : (d.tone === "bad" || d.tone === "fail" ? width * 0.12 : width / 2)
        color: (d.tone === "run" || d.tone === "warn" || d.tone === "bad") ? d.c : "transparent"
        border.width: (d.tone === "idle" || d.tone === "info" || d.tone === "fail") ? Math.max(1.5, d.size * 0.17) : 0
        border.color: d.c
        Behavior on color { ColorAnimation { duration: Theme.base } }

        SequentialAnimation on opacity {
            running: d.tone === "info"
            loops: Animation.Infinite
            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
        }
        opacity: 1
    }
}
