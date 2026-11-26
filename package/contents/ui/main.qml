import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import "logic.js" as L

PlasmoidItem {
    id: root

    readonly property var cfg: Plasmoid.configuration

    Plasmoid.icon: "dockyard"
    Plasmoid.status: Backend.tally.attention > 0 ? PlasmaCore.Types.NeedsAttentionStatus : PlasmaCore.Types.ActiveStatus
    Tr { id: tr }
    toolTipMainText: "Dockyard"
    toolTipSubText: Backend.errorKind !== "" ? i18n("Engine unreachable")
                  : !Backend.loaded ? i18n("Connecting…")
                  : i18n("%1 running · %2 stopped", Backend.tally.running, Backend.tally.stopped)
                    + (Backend.tally.attention > 0 ? " · " + i18n("%1 need attention", Backend.tally.attention) : "")

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
        function onAlertEvent(kind, c) {
            if (!root.cfg.notifications) return
            const st = L.statusInfo(c)
            let title, body = c.image
            if (kind === "crashed") { title = i18n("%1 stopped unexpectedly", c.name); body = tr.status(st) + " · " + c.image }
            else if (kind === "unhealthy") { title = i18n("%1 is unhealthy", c.name); body = i18n("Health checks are failing") + " · " + c.image }
            else title = i18n("%1 is restart-looping", c.name)
            notification.createObject(root, { title: title, body: body })
        }
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action { text: i18n("Refresh now"); icon.name: "view-refresh"; onTriggered: Backend.refresh() }
    ]
}
