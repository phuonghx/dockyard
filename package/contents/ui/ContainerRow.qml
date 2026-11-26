import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "logic.js" as L

Item {
    id: row
    required property string rid
    signal showLogs(string cid)

    readonly property var c: { Backend.revision; return Backend.cmap[rid] || null }
    readonly property bool alive: c !== null
    readonly property var st: c ? L.statusInfo(c) : ({ tone: "idle", label: "", since: "", attention: false })
    readonly property bool expanded: Backend.expandedId === rid
    readonly property string busyAction: { Backend.revision; return Backend.pending[rid] || "" }
    readonly property bool running: !!c && c.state === "running"
    readonly property bool paused: !!c && c.state === "paused"
    readonly property var img: c ? L.splitImage(c.image) : ({ name: "", tag: "" })
    readonly property var info: { Backend.revision; return Backend.inspectCache[rid] || null }
    readonly property bool engaged: hover.hovered || expanded || toggleBtn.visualFocus || logsBtn.visualFocus || restartBtn.visualFocus
    property string armed: ""

    // Stable list models: a new snapshot makes new objects with the same content, and a
    // Repeater would rebuild every chip (a visible flash). Only reassign when content changes.
    property var portList: []
    property var portHead: []
    property var netList: []
    property var mountList: []
    property string _pk: ""
    property string _nk: ""
    property string _mk: ""
    function syncLists() {
        const p = c ? c.ports : []
        let k = JSON.stringify(p)
        if (k !== _pk) { _pk = k; portList = p; portHead = p.slice(0, 2) }
        const n = info ? info.networks : []
        k = JSON.stringify(n)
        if (k !== _nk) { _nk = k; netList = n }
        const m = info ? info.mounts.slice(0, 4) : []
        k = JSON.stringify(m)
        if (k !== _mk) { _mk = k; mountList = m }
    }
    onCChanged: syncLists()
    onInfoChanged: syncLists()
    Component.onCompleted: syncLists()

    width: ListView.view ? ListView.view.width : 400
    height: alive ? card.height + Theme.s(2) : 0
    visible: alive

    onExpandedChanged: { armed = ""; if (expanded) Backend.inspect(rid) }
    Timer { id: disarm; interval: 3000; onTriggered: row.armed = "" }
    function arm(what) { armed = what; disarm.restart() }

    function openPort(p) {
        if (L.isWebPort(p.pub)) Qt.openUrlExternally("http://localhost:" + p.pub)
        else Backend.copy("localhost:" + p.pub)
    }

    Rectangle {
        id: card
        x: Theme.s(8)
        width: parent.width - Theme.s(16)
        height: head.height + detailWrap.height
        radius: Theme.s(10)
        color: row.expanded ? Theme.raised : (hover.hovered ? Theme.alpha(Theme.raised, 0.65) : "transparent")
        border.width: row.expanded ? 1 : 0
        border.color: Theme.line
        clip: true
        Behavior on color { ColorAnimation { duration: Theme.fast } }

        HoverHandler { id: hover }

        // ---------------------------------------------------------------- head
        Item {
            id: head
            width: parent.width
            height: Theme.s(54)

            QQC2.AbstractButton {
                id: headHit
                anchors.fill: parent
                focusPolicy: Qt.StrongFocus
                Accessible.name: (row.c ? row.c.name : "") + ", " + row.st.label
                Accessible.description: row.expanded ? "Expanded" : "Collapsed"
                onClicked: Backend.expandedId = row.expanded ? "" : row.rid
                background: Rectangle {
                    radius: Theme.s(10); color: "transparent"
                    border.width: headHit.visualFocus ? 2 : 0; border.color: Theme.acc
                }
                contentItem: Item {}
            }

            StatusDot {
                id: dot
                x: Theme.s(14); anchors.verticalCenter: parent.verticalCenter
                tone: row.st.tone
            }

            Column {
                id: names
                anchors { left: dot.right; leftMargin: Theme.s(12); right: rightCol.left; rightMargin: Theme.s(10); verticalCenter: parent.verticalCenter }
                spacing: Theme.s(3)
                Txt { width: parent.width; text: row.c ? row.c.name : ""; kind: "body"; strong: true; elide: Text.ElideRight }
                Row {
                    width: parent.width
                    spacing: Theme.s(8)
                    Txt {
                        width: Math.min(implicitWidth, parent.width - portsRow.width - (portsRow.width > 0 ? parent.spacing : 0))
                        text: row.img.name + ":" + row.img.tag
                        kind: "monoSm"; color: Theme.tx3; elide: Text.ElideRight
                    }
                    Row {
                        id: portsRow
                        spacing: Theme.s(4)
                        Repeater {
                            model: row.portHead
                            delegate: Chip {
                                required property var modelData
                                text: ":" + modelData.pub; mono: true; clickable: true
                                height: Theme.s(16)
                                tip: L.isWebPort(modelData.pub) ? "Open http://localhost:" + modelData.pub : "Copy localhost:" + modelData.pub
                                onClicked: row.openPort(modelData)
                            }
                        }
                        Txt { visible: !!row.c && row.c.ports.length > 2; text: "+" + (row.c ? row.c.ports.length - 2 : 0); kind: "tiny"; color: Theme.tx3 }
                    }
                }
            }

            Item {
                id: rightCol
                width: Theme.s(122)
                height: parent.height
                anchors.right: parent.right
                anchors.rightMargin: Theme.s(10)

                // status text; swaps with quick actions on hover / focus / expanded
                Column {
                    anchors { right: toggleBtn.left; rightMargin: Theme.s(8); verticalCenter: parent.verticalCenter }
                    spacing: Theme.s(3)
                    opacity: row.engaged ? 0 : 1
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                    Txt {
                        anchors.right: parent.right
                        text: row.st.label + (row.st.since && row.running ? " · " + row.st.since : "")
                        kind: "tiny"; strong: true; color: row.st.tone === "idle" ? Theme.tx3 : Theme.tone(row.st.tone)
                    }
                    Txt {
                        anchors.right: parent.right
                        text: row.running ? L.fmtPct(row.c.cpu) + "  " + L.fmtBytes(row.c.mem)
                                          : (row.st.since && !row.running ? row.st.since + " ago" : "")
                        kind: "monoSm"; color: Theme.tx3
                    }
                }
                Row {
                    anchors { right: toggleBtn.left; rightMargin: Theme.s(2); verticalCenter: parent.verticalCenter }
                    spacing: Theme.s(2)
                    opacity: row.engaged ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: Theme.fast } }
                    IconButton { id: logsBtn; symbol: "logs"; tip: "Logs"; onClicked: row.showLogs(row.rid) }
                    IconButton { id: restartBtn; symbol: "restart"; tip: "Restart"; enabled: !row.busyAction
                        visible: row.running || row.paused || (row.c && row.c.state === "restarting")
                        busy: row.busyAction === "restart"
                        onClicked: Backend.act("restart", [row.rid]) }
                }
                IconButton {
                    id: toggleBtn
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    symbol: row.running || row.paused || (row.c && row.c.state === "restarting") ? "stop" : "play"
                    solid: !(row.running || row.paused) && !(row.c && row.c.state === "restarting")
                    tone: "accent"
                    busy: row.busyAction === "start" || row.busyAction === "stop"
                    enabled: !row.busyAction
                    tip: symbol === "stop" ? "Stop" : "Start"
                    onClicked: Backend.act(symbol === "stop" ? "stop" : "start", [row.rid])
                }
            }
        }

        // -------------------------------------------------------------- details
        Item {
            id: detailWrap
            y: head.height
            width: parent.width
            height: row.expanded ? detail.implicitHeight + Theme.s(16) : 0
            clip: true
            opacity: row.expanded ? 1 : 0
            Behavior on height { NumberAnimation { duration: Theme.base; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: Theme.base } }

            ColumnLayout {
                id: detail
                x: Theme.s(36)
                width: parent.width - Theme.s(36) - Theme.s(14)
                spacing: Theme.s(12)

                RowLayout {
                    visible: row.running
                    Layout.fillWidth: true
                    spacing: Theme.s(16)
                    Meter { Layout.fillWidth: true; label: "CPU"; value: row.c ? L.fmtPct(row.c.cpu) : ""
                            fraction: row.c ? row.c.cpu / 100 / Math.max(1, (Backend.engine.ncpu || 1) / 4) : 0 }
                    Meter { Layout.fillWidth: true; label: "Memory"; value: row.c ? L.fmtBytes(row.c.mem) : ""
                            fraction: row.c && row.c.memLimit ? row.c.mem / row.c.memLimit : 0 }
                    Meter { Layout.fillWidth: true; label: "Network ↓ ↑"; value: row.c ? L.fmtBytes(row.c.netRx) + " · " + L.fmtBytes(row.c.netTx) : ""; fraction: 0 }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: Theme.s(14)
                    rowSpacing: Theme.s(7)

                    Txt { text: "Image"; kind: "tiny"; color: Theme.tx3; Layout.alignment: Qt.AlignTop }
                    Txt { Layout.fillWidth: true; text: row.c ? row.c.image : ""; kind: "monoSm"; color: Theme.tx2; elide: Text.ElideMiddle }

                    Txt { visible: !!row.c && row.c.project !== ""; text: "Compose"; kind: "tiny"; color: Theme.tx3 }
                    Txt { visible: !!row.c && row.c.project !== ""; Layout.fillWidth: true; text: row.c ? row.c.project + " / " + row.c.service : ""; kind: "small"; color: Theme.tx2; elide: Text.ElideRight }

                    Txt { visible: !!row.c && row.c.ports.length > 0; text: "Ports"; kind: "tiny"; color: Theme.tx3; Layout.alignment: Qt.AlignTop }
                    Flow {
                        visible: !!row.c && row.c.ports.length > 0
                        Layout.fillWidth: true
                        spacing: Theme.s(5)
                        Repeater {
                            model: row.portList
                            delegate: Chip {
                                required property var modelData
                                text: modelData.pub + " → " + modelData.priv + "/" + modelData.proto
                                mono: true; clickable: true; glyph: L.isWebPort(modelData.pub) ? "external" : "copy"
                                tip: L.isWebPort(modelData.pub) ? "Open in browser" : "Copy address"
                                onClicked: row.openPort(modelData)
                            }
                        }
                    }

                    Txt { visible: !!row.info && row.info.networks.length > 0; text: "Network"; kind: "tiny"; color: Theme.tx3; Layout.alignment: Qt.AlignTop }
                    Column {
                        visible: !!row.info && row.info.networks.length > 0
                        Layout.fillWidth: true
                        spacing: Theme.s(2)
                        Repeater {
                            model: row.netList
                            delegate: Txt { required property var modelData; text: modelData.name + (modelData.ip ? "  " + modelData.ip : ""); kind: "monoSm"; color: Theme.tx2 }
                        }
                    }

                    Txt { visible: !!row.info && row.info.mounts.length > 0; text: "Mounts"; kind: "tiny"; color: Theme.tx3; Layout.alignment: Qt.AlignTop }
                    Column {
                        visible: !!row.info && row.info.mounts.length > 0
                        Layout.fillWidth: true
                        spacing: Theme.s(2)
                        Repeater {
                            model: row.mountList
                            delegate: Txt {
                                required property var modelData
                                width: parent.width
                                text: (modelData.src.length > 22 && modelData.type !== "volume" ? "…" + modelData.src.slice(-20) : modelData.src) + " → " + modelData.dst
                                kind: "monoSm"; color: Theme.tx2; elide: Text.ElideMiddle
                            }
                        }
                    }

                    Txt { visible: !!row.info; text: "Policy"; kind: "tiny"; color: Theme.tx3 }
                    Txt { visible: !!row.info; text: row.info ? row.info.restartPolicy + (row.info.restarts ? " · restarted " + row.info.restarts + "×" : "") : ""; kind: "small"; color: Theme.tx2 }

                    Txt { text: "ID"; kind: "tiny"; color: Theme.tx3 }
                    Chip { text: row.c ? row.c.short : ""; mono: true; clickable: true; glyph: "copy"; tip: "Copy full ID"; onClicked: Backend.copy(row.c.id) }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Theme.s(6)
                    IconButton { symbol: "logs"; label: "Logs"; onClicked: row.showLogs(row.rid) }
                    IconButton { symbol: "terminal"; label: "Shell"; visible: row.running; onClicked: Backend.openTerminal(row.rid) }
                    IconButton { symbol: row.paused ? "play" : "pause"; label: row.paused ? "Resume" : "Pause"; visible: row.running || row.paused
                        enabled: !row.busyAction; onClicked: Backend.act(row.paused ? "unpause" : "pause", [row.rid]) }
                    IconButton { symbol: "bolt"; label: row.armed === "kill" ? "Kill now?" : "Kill"; visible: row.running; armed: row.armed === "kill"
                        tone: "danger"; enabled: !row.busyAction
                        onClicked: { if (row.armed === "kill") { row.armed = ""; Backend.act("kill", [row.rid]) } else row.arm("kill") } }
                    IconButton { symbol: "trash"; label: row.armed === "rm" ? "Remove for good?" : "Remove"; armed: row.armed === "rm"
                        tone: "danger"; enabled: !row.busyAction
                        onClicked: { if (row.armed === "rm") { row.armed = ""; Backend.act("rm", [row.rid]) } else row.arm("rm") } }
                }
            }
        }
    }
}
