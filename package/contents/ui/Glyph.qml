import QtQuick
import QtQuick.Shapes
import "Icons.js" as Icons

Item {
    id: g
    property string name: ""
    property color color: Theme.tx2
    property real size: Theme.s(16)
    property real weight: 1.75
    property bool filled: false
    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    Shape {
        width: 24; height: 24
        anchors.centerIn: parent
        scale: g.size / 24
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: g.filled ? "transparent" : g.color
            fillColor: g.filled ? g.color : "transparent"
            strokeWidth: g.weight
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: Icons.paths[g.name] || "" }
        }
    }
}
