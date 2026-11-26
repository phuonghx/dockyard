import QtQuick
import QtQuick.Layouts
import "logic.js" as L

// One row for images, volumes and networks: they share the shape, only the facts differ.
Item {
    id: row
    required property string rid
    property string type: "image"        // image | volume | network

    readonly property var r: {
        Backend.revision
        return (type === "image" ? Backend.imap : type === "volume" ? Backend.vmap : Backend.nmap)[rid] || null
    }
    readonly property bool alive: r !== null
    property bool armed: false
    Tr { id: tr }
    Timer { id: disarm; interval: 3000; onTriggered: row.armed = false }

    readonly property var parts: type === "image" && r ? L.splitImage(r.tags[0] || "") : ({ name: "", tag: "" })
    readonly property string title: !r ? "" : type === "image" ? (r.tags.length ? parts.name : L10n.t("<untagged>"))
                                    : type === "volume" ? (r.anonymous ? r.name.slice(0, 12) : r.name) : r.name
    readonly property string sub: {
        if (!r) return ""
        if (type === "image") return r.short + "  ·  " + L.fmtBytes(r.size) + "  ·  " + tr.ago(r.created)
        if (type === "volume") {
            const sz = Backend.df && Backend.df.volumeSizes && Backend.df.volumeSizes[r.name] >= 0 ? "  ·  " + L.fmtBytes(Backend.df.volumeSizes[r.name]) : ""
            return r.driver + (r.project ? "  ·  " + r.project : "") + sz
        }
        return r.driver + "  ·  " + r.scope + (r.internal ? "  ·  " + L10n.t("internal") : "")
    }
    readonly property string badge: !r ? "" : type === "network" ? L10n.tn("%1 container", "%1 containers", r.used)
                                    : (r.used > 0 ? L10n.t("In use") : (r.dangling ? L10n.t("Dangling") : L10n.t("Unused")))
    readonly property string badgeTone: !r ? "neutral" : (r.used > 0 ? "run" : (type === "network" ? "neutral" : "warn"))
    readonly property bool removable: !!r && !(type === "network" && r.system) && !(type !== "network" && r.used > 0 && false)

    width: ListView.view ? ListView.view.width : 400
    height: alive ? Theme.s(54) : 0
    visible: alive

    Rectangle {
        x: Theme.s(8); width: parent.width - Theme.s(16); height: parent.height - Theme.s(2); radius: Theme.s(10)
        color: hover.hovered ? Theme.alpha(Theme.raised, 0.65) : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.fast } }
        HoverHandler { id: hover }

        Rectangle {
            id: tile
            x: Theme.s(8); anchors.verticalCenter: parent.verticalCenter
            width: Theme.s(30); height: width; radius: Theme.s(8)
            color: Theme.alpha(Theme.tx, 0.06)
            Glyph { anchors.centerIn: parent; size: Theme.s(16); color: row.r && row.r.used > 0 ? Theme.acc : Theme.tx3
                name: row.type === "image" ? "layers" : row.type === "volume" ? "volume" : "network" }
        }

        Column {
            anchors { left: tile.right; leftMargin: Theme.s(12); right: tail.left; rightMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
            spacing: Theme.s(3)
            Row {
                width: parent.width
                spacing: Theme.s(6)
                Txt { width: Math.min(implicitWidth, parent.width - (tagChip.visible ? tagChip.width + parent.spacing : 0)); text: row.title; kind: "body"; strong: true; elide: Text.ElideRight
                      font.family: row.type === "volume" && row.r && row.r.anonymous ? Theme.mono : Theme.sans }
                Chip { id: tagChip; visible: row.type === "image" && !!row.r && row.r.tags.length > 0; text: row.parts.tag + (row.r && row.r.tags.length > 1 ? " +" + (row.r.tags.length - 1) : ""); mono: true; height: Theme.s(17) }
                Chip { visible: row.type === "volume" && !!row.r && row.r.anonymous; text: L10n.t("anonymous"); height: Theme.s(17) }
                Chip { visible: row.type === "network" && !!row.r && row.r.system; text: L10n.t("system"); height: Theme.s(17) }
            }
            Txt { width: parent.width; text: row.sub; kind: "monoSm"; color: Theme.tx3; elide: Text.ElideRight }
        }

        Row {
            id: tail
            anchors { right: parent.right; rightMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
            spacing: Theme.s(6)
            Chip { anchors.verticalCenter: parent.verticalCenter; text: row.badge; tone: row.badgeTone }
            IconButton {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.removable
                opacity: hover.hovered || row.armed || visualFocus ? 1 : 0
                symbol: "trash"; tone: "danger"; armed: row.armed
                label: row.armed ? L10n.t("Remove?") : ""
                tip: row.type === "image" ? L10n.t("Remove image") : row.type === "volume" ? L10n.t("Remove volume") : L10n.t("Remove network")
                Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                onClicked: {
                    if (!row.armed) { row.armed = true; disarm.restart(); return }
                    row.armed = false
                    Backend.removeResource(row.type === "image" ? "rmi" : row.type === "volume" ? "rmvol" : "rmnet", row.r.id, row.title)
                }
            }
        }
    }
}
