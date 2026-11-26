import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "logic.js" as L

// The panel icon: the fleet in miniature.
Item {
    id: c
    signal toggle()
    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    readonly property bool inPanel: vertical || Plasmoid.formFactor === PlasmaCore.Types.Horizontal
    // Size from the panel thickness only (never from our own width), so we can't feed back on ourselves.
    readonly property real s: Math.max(Kirigami.Units.iconSizes.small,
                                       inPanel ? (vertical ? width : height) : Math.min(width, height))
    readonly property bool showCount: Plasmoid.configuration.showCount && !vertical && Backend.loaded && Backend.errorKind === ""
    // exactly the width of the number, nothing more
    readonly property real labelW: showCount ? Math.ceil(metrics.width) + Kirigami.Units.smallSpacing : 0
    TextMetrics { id: metrics; font: label.font; text: String(Backend.tally.running) }
    readonly property var tonesNow: { Backend.revision; return Backend.errorKind !== "" ? [] : L.markTones(Backend.containers) }

    // what we actually got: the system tray hands out cells narrower than they are tall,
    // so the mark shrinks to fit instead of overflowing (and being clipped) on the right
    readonly property real markSize: width > 0 ? Math.max(Kirigami.Units.iconSizes.small * 0.6, Math.min(s, width - labelW)) : s
    implicitWidth: s + labelW
    implicitHeight: s
    // Fixed footprint: exactly the icon (+ count, if enabled). Neighbours keep their own space.
    Layout.minimumWidth: vertical ? 0 : s + labelW
    Layout.preferredWidth: vertical ? -1 : s + labelW
    Layout.maximumWidth: vertical ? -1 : s + labelW
    Layout.minimumHeight: vertical ? s : 0
    Layout.preferredHeight: vertical ? s : -1

    Mark {
        id: mark
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        size: c.markSize
        outline: Kirigami.Theme.textColor
        deck: Backend.errorKind !== "" ? Theme.bad : Kirigami.Theme.textColor
        tones: c.tonesNow
    }

    Text {
        id: label
        visible: c.showCount
        anchors { left: mark.right; leftMargin: Kirigami.Units.smallSpacing; verticalCenter: parent.verticalCenter }
        text: Backend.tally.running
        color: Kirigami.Theme.textColor
        font.family: Theme.sans
        font.pixelSize: Math.max(10, c.markSize * 0.55)
        font.weight: Font.DemiBold
        font.features: { "tnum": 1 }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        hoverEnabled: true
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton) Backend.refresh()
            else c.toggle()
        }
    }
}
