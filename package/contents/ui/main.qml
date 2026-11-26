import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration

    Plasmoid.icon: "dockyard"
    Plasmoid.status: Backend.tally.attention > 0 ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.ActiveStatus
    toolTipMainText: "Dockyard"
    toolTipSubText: Backend.errorKind !== "" ? "Engine unreachable"
                  : !Backend.loaded ? "Connecting…"
                  : Backend.tally.running + " running · " + Backend.tally.stopped + " stopped"
                    + (Backend.tally.attention > 0 ? " · " + Backend.tally.attention + " need attention" : "")

    compactRepresentation: Compact { onToggle: root.expanded = !root.expanded }
    fullRepresentation: Full {}

    // push settings into the shared backend / theme
    Binding { target: Backend; property: "socketPath"; value: root.cfg.socket }
    Binding { target: Backend; property: "cli"; value: root.cfg.cli }
    Binding { target: Backend; property: "terminal"; value: root.cfg.terminal }
    Binding { target: Backend; property: "notify"; value: root.cfg.notifications }
    Binding { target: Theme; property: "mode"; value: root.cfg.theme }
    Binding { target: Theme; property: "sysLightness"; value: Kirigami.Theme.backgroundColor.hslLightness }
    Binding { target: Theme; property: "unit"; value: Math.max(0.85, Kirigami.Units.gridUnit / 18) }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        interval: (Backend.active ? root.cfg.interval : root.cfg.backgroundInterval) * 1000
        onTriggered: Backend.refresh()
    }
    onExpandedChanged: if (expanded) Backend.refresh()

    // desktop notifications: crashes, failing health checks, restart loops
    Component {
        id: notification
        Loader {
            source: "Notifier.qml"
            onLoaded: item.send(title, body)
            property string title
            property string body
        }
    }
    Connections {
        target: Backend
        function onAlert(title, body) { if (root.cfg.notifications) notification.createObject(root, { title: title, body: body }) }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action { text: "Refresh now"; icon.name: "view-refresh"; onTriggered: Backend.refresh() }
    ]
}
