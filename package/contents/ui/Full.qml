import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import Qt.labs.qmlmodels
import org.kde.plasma.plasmoid
import "logic.js" as L

Item {
    id: root
    Layout.minimumWidth: Theme.s(420)
    Layout.minimumHeight: Theme.s(520)
    Layout.preferredWidth: Theme.s(460)
    Layout.preferredHeight: Theme.s(700)

    property int tab: Plasmoid.configuration.defaultTab   // 0 containers, 1 images, 2 volumes, 3 networks
    property string filter: "all"             // all | running | attention | stopped
    property bool grouped: Plasmoid.configuration.grouped
    property bool unusedOnly: false
    property var collapsed: ({})
    readonly property string query: search.text

    onVisibleChanged: Backend.active = visible
    Component.onCompleted: { Backend.active = visible; rebuild() }

    // ------------------------------------------------------------ list models
    ListModel { id: cModel }
    ListModel { id: iModel }
    ListModel { id: vModel }
    ListModel { id: nModel }

    function rebuild() {
        if (!Backend.loaded) return
        // a refresh must never move what the user is looking at
        const lists = [cList, iList, vList, nList]
        const saved = lists.map(l => l.contentY)
        L.syncModel(cModel, L.containerView(Backend.containers, { query: query, filter: filter, group: grouped, collapsed: collapsed }))
        L.syncModel(iModel, L.resourceView(Backend.images, { query: query, unusedOnly: unusedOnly }, r => r.tags.concat([r.short])))
        L.syncModel(vModel, L.resourceView(Backend.volumes, { query: query, unusedOnly: unusedOnly }, r => [r.name, r.project]))
        L.syncModel(nModel, L.resourceView(Backend.networks, { query: query, unusedOnly: unusedOnly }, r => [r.name, r.driver]))
        lists.forEach((l, i) => { if (saved[i] > 0 && Math.abs(l.contentY - saved[i]) > 0.5) l.contentY = Math.min(saved[i], Math.max(0, l.contentHeight - l.height)) })
    }
    Timer { id: rb; interval: 0; onTriggered: root.rebuild() }
    function schedule() { rb.restart() }
    Connections { target: Backend; function onRevisionChanged() { root.schedule() } function onLoadedChanged() { root.schedule() } }
    onQueryChanged: schedule()
    onFilterChanged: schedule()
    onGroupedChanged: schedule()
    onCollapsedChanged: schedule()
    onUnusedOnlyChanged: schedule()

    function toggleGroup(g) {
        const x = Object.assign({}, collapsed)
        if (x[g]) delete x[g]; else x[g] = true
        collapsed = x
    }
    function jumpTo(cid) {
        tab = 0; filter = "all"; search.text = ""
        const c = Backend.cmap[cid]
        if (c && collapsed[c.project || ""]) toggleGroup(c.project || "")
        rebuild()
        Backend.expandedId = cid
        Qt.callLater(() => {
            for (let i = 0; i < cModel.count; i++)
                if (cModel.get(i).key === "c:" + cid) { cList.positionViewAtIndex(i, ListView.Contain); break }
        })
        manifest.highlightId = cid
        hl.restart()
    }
    Timer { id: hl; interval: 1600; onTriggered: manifest.highlightId = "" }

    // codes from Backend -> words in the user's language
    function noticeText(code, a, b) {
        switch (code) {
        case "acted": {
            const who = b.charAt(0) === "#" ? L10n.tn("%1 container", "%1 containers", parseInt(b.slice(1))) : b
            switch (a) {
            case "start": return L10n.t("Started %1", who)
            case "stop": return L10n.t("Stopped %1", who)
            case "restart": return L10n.t("Restarted %1", who)
            case "pause": return L10n.t("Paused %1", who)
            case "unpause": return L10n.t("Resumed %1", who)
            case "kill": return L10n.t("Killed %1", who)
            default: return L10n.t("Removed %1", who)
            }
        }
        case "act-failed": return L10n.t("That didn't work")
        case "removed": return L10n.t("Removed %1", a)
        case "remove-failed": return L10n.t("Could not remove %1", a)
        case "reclaimed": return L10n.t("Reclaimed %1", a)
        case "nothing-to-clean": return L10n.t("Nothing to clean")
        case "prune-failed": return L10n.t("Cleanup failed")
        case "starting-docker": return L10n.t("Asking systemd to start Docker…")
        case "docker-up": return L10n.t("Docker is up")
        case "docker-start-failed": return a ? L10n.t("Could not start Docker: %1", a) : L10n.t("Could not start Docker")
        default: return a
        }
    }

    // ---------------------------------------------------------- clipboard + toast
    TextEdit { id: clip; visible: false }
    Connections {
        target: Backend
        function onCopyRequested(text) { clip.text = text; clip.selectAll(); clip.copy(); toast.show(L10n.t("Copied to clipboard"), "ok") }
        function onToast(text, tone) { toast.show(text, tone) }
        function onNotice(code, a, b, tone) { toast.show(root.noticeText(code, a, b), tone) }
    }
    Timer { id: dfTimer; interval: 60000; repeat: true; running: root.visible; triggeredOnStart: true; onTriggered: Backend.fetchDf() }

    Shortcut { sequences: [StandardKey.Find]; enabled: root.visible; onActivated: search.focusField() }
    Shortcut { sequence: "Escape"; enabled: logs.showing || prune.shown || langMenu.shown
        onActivated: { if (langMenu.shown) langMenu.shown = false; else if (prune.shown) prune.shown = false; else logs.showing = false } }

    // ------------------------------------------------------------ inline parts
    component TabBtn: QQC2.AbstractButton {
        id: tb
        property string symbol
        property int count: 0
        property bool current: false
        implicitHeight: Theme.s(34)
        Layout.fillWidth: true
        hoverEnabled: true
        focusPolicy: Qt.TabFocus
        Accessible.name: text + ", " + count
        background: Rectangle {
            radius: Theme.s(8)
            color: tb.current ? Theme.raised : (tb.hovered ? Theme.alpha(Theme.tx, 0.05) : "transparent")
            border.width: tb.visualFocus ? 2 : (tb.current ? 1 : 0)
            border.color: tb.visualFocus ? Theme.acc : Theme.line
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        contentItem: Item {
            implicitWidth: tbRow.implicitWidth
            implicitHeight: tbRow.implicitHeight
            Row {
                id: tbRow
                spacing: Theme.s(5)
                anchors.centerIn: parent
                Glyph { anchors.verticalCenter: parent.verticalCenter; name: tb.symbol; size: Theme.s(14); color: tb.current ? Theme.acc : Theme.tx3 }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: tb.text; kind: "small"; strong: tb.current; color: tb.current ? Theme.tx : Theme.tx2 }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: tb.count; kind: "tiny"; color: Theme.tx3; tnum: true }
            }
        }
    }

    component Token: QQC2.AbstractButton {
        id: tk
        property string tone: "run"
        property int n: 0
        property bool current: false
        implicitHeight: Theme.s(26)
        implicitWidth: tkRow.implicitWidth + Theme.s(18)
        hoverEnabled: true
        focusPolicy: Qt.TabFocus
        Accessible.name: n + " " + text
        background: Rectangle {
            radius: height / 2
            color: tk.current ? Theme.alpha(Theme.tx, 0.10) : (tk.hovered ? Theme.alpha(Theme.tx, 0.06) : "transparent")
            border.width: tk.visualFocus ? 2 : 1
            border.color: tk.visualFocus ? Theme.acc : (tk.current ? Theme.lineStrong : Theme.line)
            Behavior on color { ColorAnimation { duration: Theme.fast } }
        }
        contentItem: Item {
            implicitWidth: tkRow.implicitWidth
            implicitHeight: tkRow.implicitHeight
            Row {
                id: tkRow
                spacing: Theme.s(6)
                anchors.centerIn: parent
                StatusDot { anchors.verticalCenter: parent.verticalCenter; tone: tk.tone; size: Theme.s(8) }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: tk.n; kind: "small"; strong: true; tnum: true }
                Txt { anchors.verticalCenter: parent.verticalCenter; text: tk.text; kind: "small"; color: Theme.tx2 }
            }
        }
    }

    component FleetMeter: Item {
        id: fm
        property string label
        property string value
        property string unit
        property string note
        property var series: []
        property real ceiling: 1
        implicitHeight: Theme.s(44)
        Column {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: Theme.s(2)
            Txt { text: fm.label; kind: "tiny"; color: Theme.tx3 }
            Row {
                spacing: Theme.s(5)
                Txt { text: fm.value; kind: "title"; strong: true; tnum: true }
                Txt { anchors.baseline: parent.children[0].baseline; text: fm.unit; kind: "small"; color: Theme.tx2 }
            }
            Txt { text: fm.note; kind: "tiny"; color: Theme.tx3; visible: text.length > 0 }
        }
        Sparkline {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            width: Math.min(Theme.s(110), parent.width * 0.5); height: Theme.s(34)
            values: fm.series; ceiling: fm.ceiling
        }
    }

    // -------------------------------------------------------------------- body
    Rectangle { anchors.fill: parent; color: Theme.surface }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.s(58)
            color: Theme.shell
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.s(14); rightMargin: Theme.s(10) }
                spacing: Theme.s(10)
                Mark {
                    size: Theme.s(34)
                    tones: { Backend.revision; return Backend.errorKind !== "" ? [] : L.markTones(Backend.containers) }
                    deck: Backend.errorKind !== "" ? Theme.bad : Theme.tx3
                }
                ColumnLayout {
                    spacing: Theme.s(1)
                    Txt { text: "Dockyard"; kind: "title"; strong: true }
                    Txt { text: L10n.t("Keep every container shipshape."); kind: "tiny"; color: Theme.tx3 }
                }
                Item { Layout.fillWidth: true }
                IconButton { symbol: "refresh"; tip: L10n.t("Refresh now"); busy: Backend.refreshing && Backend.manual; onClicked: Backend.refresh(true) }
                IconButton { symbol: "globe"; tip: L10n.t("Language"); onClicked: langMenu.shown = !langMenu.shown }
                IconButton { symbol: "settings"; tip: L10n.t("Configure Dockyard")
                    onClicked: { const a = Plasmoid.internalAction("configure"); if (a) a.trigger() } }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }
        }

        // overview: load, the manifest, and the state filters
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.s(16)
            Layout.rightMargin: Theme.s(16)
            Layout.topMargin: Theme.s(12)
            spacing: Theme.s(12)
            visible: Backend.loaded && Backend.errorKind === ""

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.s(20)
                FleetMeter {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    label: L10n.t("CPU"); value: L.fmtCores(Backend.cpuCores * 100); unit: Backend.cpuCores === 1 ? L10n.tc("unit, singular", "core") : L10n.tc("unit, plural", "cores")
                    note: L10n.t("of %1 available", Backend.engine.ncpu || "?")
                    series: Backend.cpuHistory
                    ceiling: Math.max(0.2, Math.max.apply(null, Backend.cpuHistory.concat([0])) * 1.35)
                }
                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: Theme.s(36); color: Theme.line }
                FleetMeter {
                    Layout.fillWidth: true; Layout.preferredWidth: 1
                    label: L10n.t("Memory")
                    value: L.fmtBytes(Backend.memUsed).split(" ")[0]; unit: L.fmtBytes(Backend.memUsed).split(" ")[1]
                    note: L10n.t("of %1", L.fmtBytes(Backend.engine.memTotal || 0))
                    series: Backend.memHistory
                    ceiling: Math.max(1, Math.max.apply(null, Backend.memHistory.concat([0])) * 1.25)
                }
            }

            Manifest {
                id: manifest
                Layout.fillWidth: true
                onPicked: cid => root.jumpTo(cid)
            }

            Flow {
                Layout.fillWidth: true
                spacing: Theme.s(6)
                Token { text: L10n.tc("filter: containers that are running", "running"); tone: "run"; n: Backend.tally.running; current: root.tab === 0 && root.filter === "running"
                        onClicked: { root.tab = 0; root.filter = root.filter === "running" ? "all" : "running" } }
                Token { text: L10n.tc("filter: containers that need attention", "need attention"); tone: "bad"; n: Backend.tally.attention; visible: n > 0; current: root.tab === 0 && root.filter === "attention"
                        onClicked: { root.tab = 0; root.filter = root.filter === "attention" ? "all" : "attention" } }
                Token { text: L10n.tc("filter: containers that are stopped", "stopped"); tone: "idle"; n: Backend.tally.stopped; current: root.tab === 0 && root.filter === "stopped"
                        onClicked: { root.tab = 0; root.filter = root.filter === "stopped" ? "all" : "stopped" } }
                Token { text: L10n.tc("filter: containers that are paused", "paused"); tone: "warn"; n: Backend.tally.paused; visible: n > 0; current: false; enabled: false }
            }
        }

        // tabs + search
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Theme.s(10)
            Layout.rightMargin: Theme.s(10)
            Layout.topMargin: Theme.s(12)
            spacing: Theme.s(8)
            visible: Backend.loaded && Backend.errorKind === ""

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.s(2)
                TabBtn { text: L10n.t("Containers"); symbol: "box"; count: Backend.containers.length; current: root.tab === 0; onClicked: root.tab = 0 }
                TabBtn { text: L10n.t("Images"); symbol: "layers"; count: Backend.images.length; current: root.tab === 1; onClicked: root.tab = 1 }
                TabBtn { text: L10n.t("Volumes"); symbol: "volume"; count: Backend.volumes.length; current: root.tab === 2; onClicked: root.tab = 2 }
                TabBtn { text: L10n.t("Networks"); symbol: "network"; count: Backend.networks.length; current: root.tab === 3; onClicked: root.tab = 3 }
            }
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.s(4); Layout.rightMargin: Theme.s(4)
                spacing: Theme.s(6)
                SearchField {
                    id: search
                    Layout.fillWidth: true
                    placeholder: [L10n.t("Search containers, images, ports"), L10n.t("Search images"), L10n.t("Search volumes"), L10n.t("Search networks")][root.tab]
                }
                IconButton {
                    visible: root.tab === 0
                    symbol: "layers"; tip: root.grouped ? L10n.t("Grouped by Compose project") : L10n.t("Group by Compose project")
                    tone: root.grouped ? "accent" : "neutral"
                    implicitWidth: Theme.s(32); implicitHeight: Theme.s(32)
                    onClicked: Plasmoid.configuration.grouped = !root.grouped
                }
                IconButton {
                    visible: root.tab !== 0
                    symbol: "trash"; tip: root.unusedOnly ? L10n.t("Showing unused only") : L10n.t("Show unused only")
                    tone: root.unusedOnly ? "accent" : "neutral"
                    implicitWidth: Theme.s(32); implicitHeight: Theme.s(32)
                    onClicked: root.unusedOnly = !root.unusedOnly
                }
            }
        }

        // list area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: Theme.s(6)

            Skeleton { width: parent.width; visible: !Backend.loaded }

            // the four lists
            ListView {
                id: cList
                anchors.fill: parent
                visible: Backend.loaded && Backend.errorKind === "" && root.tab === 0
                model: cModel
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                reuseItems: false
                cacheBuffer: 400
                QQC2.ScrollBar.vertical: ThemedScrollBar {}
                delegate: DelegateChooser {
                    role: "kind"
                    DelegateChoice { roleValue: "header"; GroupHeader { onToggled: g => root.toggleGroup(g) } }
                    DelegateChoice { roleValue: "row"; ContainerRow { onShowLogs: id => logs.openFor(id) } }
                }
                add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.base } }
                displaced: Transition { NumberAnimation { properties: "y"; duration: Theme.base; easing.type: Easing.OutCubic } }
            }
            ListView {
                id: iList
                anchors.fill: parent; clip: true; model: iModel; boundsBehavior: Flickable.StopAtBounds
                visible: Backend.loaded && Backend.errorKind === "" && root.tab === 1
                QQC2.ScrollBar.vertical: ThemedScrollBar {}
                delegate: ResourceRow { type: "image" }
            }
            ListView {
                id: vList
                anchors.fill: parent; clip: true; model: vModel; boundsBehavior: Flickable.StopAtBounds
                visible: Backend.loaded && Backend.errorKind === "" && root.tab === 2
                QQC2.ScrollBar.vertical: ThemedScrollBar {}
                delegate: ResourceRow { type: "volume" }
            }
            ListView {
                id: nList
                anchors.fill: parent; clip: true; model: nModel; boundsBehavior: Flickable.StopAtBounds
                visible: Backend.loaded && Backend.errorKind === "" && root.tab === 3
                QQC2.ScrollBar.vertical: ThemedScrollBar {}
                delegate: ResourceRow { type: "network" }
            }

            // empty: nothing matches
            EmptyState {
                anchors.fill: parent
                visible: Backend.loaded && Backend.errorKind === "" && [cModel, iModel, vModel, nModel][root.tab].count === 0
                icon: root.query !== "" || root.filter !== "all" || root.unusedOnly ? "search" : ["box", "layers", "volume", "network"][root.tab]
                title: root.query !== "" ? L10n.t("Nothing matches “%1”", root.query)
                     : (root.tab === 0 && root.filter !== "all") ? L10n.t("No containers in this state")
                     : root.unusedOnly ? L10n.t("Nothing unused. Tidy ship.")
                     : root.tab === 0 ? L10n.t("The dockyard is empty")
                     : [L10n.t("No containers here"), L10n.t("No images here"), L10n.t("No volumes here"), L10n.t("No networks here")][root.tab]
                body: root.query !== "" || root.filter !== "all" || root.unusedOnly ? "" : root.tab === 0 ? L10n.t("Start a container and it will show up here.") : ""
                IconButton {
                    visible: root.query !== "" || root.filter !== "all" || root.unusedOnly
                    label: L10n.t("Clear filters"); symbol: "close"
                    onClicked: { search.text = ""; root.filter = "all"; root.unusedOnly = false }
                }
                IconButton {
                    visible: root.tab === 0 && root.query === "" && root.filter === "all"
                    label: L10n.t("Copy a first command"); symbol: "copy"; solid: true
                    onClicked: Backend.copy("docker run -d --name hello -p 8080:80 nginx")
                }
            }

            // engine problems
            EmptyState {
                anchors.fill: parent
                visible: Backend.loaded && Backend.errorKind !== ""
                tone: Backend.errorKind === "not_running" ? "warn" : "bad"
                icon: Backend.errorKind === "not_running" ? "power" : "warning"
                title: Backend.errorKind === "not_running" ? L10n.t("Docker isn't running")
                     : Backend.errorKind === "permission_denied" ? L10n.t("Dockyard can't reach Docker yet")
                     : Backend.errorKind === "no_socket" ? L10n.t("No container engine found")
                     : L10n.t("Something went wrong")
                body: Backend.errorKind === "permission_denied" ? L10n.t("Your account isn't allowed to use the Docker socket. Add yourself to the docker group, then sign out and back in.")
                    : Backend.errorKind === "not_running" ? L10n.t("The socket exists but nothing is answering. Start the engine and Dockyard will pick it up.")
                    : Backend.errorKind === "no_socket" ? L10n.t("Install Docker or enable Podman's socket, then reopen this panel.")
                    : (Backend.errorMessage || L10n.t("Dockyard could not run its helper. Make sure python3 is installed."))
                IconButton { visible: Backend.errorKind === "not_running"; label: L10n.t("Start Docker"); symbol: "power"; solid: true; onClicked: Backend.startEngine() }
                IconButton { visible: Backend.errorHint !== ""; label: L10n.t("Copy fix"); symbol: "copy"; onClicked: Backend.copy(Backend.errorHint) }
                IconButton { label: L10n.t("Retry"); symbol: "refresh"; onClicked: Backend.refresh() }
            }
        }

        // footer
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.s(42)
            color: Theme.shell
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.line }
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.s(14); rightMargin: Theme.s(8) }
                spacing: Theme.s(8)
                StatusDot { tone: Backend.errorKind !== "" ? "bad" : (Backend.loaded ? "run" : "idle"); size: Theme.s(8) }
                Txt {
                    text: Backend.errorKind !== "" ? L10n.t("Engine unreachable") : (Backend.engine.name ? Backend.engine.name + " " + Backend.engine.version : L10n.t("Connecting…"))
                    kind: "tiny"; color: Theme.tx2
                }
                Txt {
                    Layout.fillWidth: true
                    text: (Backend.engine.rootless ? L10n.t("rootless") + " · " : "") + (Backend.engine.socket || "")
                    kind: "monoSm"; color: Theme.tx3; elide: Text.ElideMiddle
                }
                IconButton {
                    visible: Backend.loaded && Backend.errorKind === ""
                    symbol: "broom"
                    label: Backend.df ? L10n.t("Free up %1", L.fmtBytes(Backend.df.imagesReclaimable + Backend.df.containersReclaimable + Backend.df.cacheReclaimable)) : L10n.t("Free up space")
                    onClicked: prune.shown = true
                }
            }
        }
    }

    // ------------------------------------------------------------------ overlays
    PrunePanel { id: prune; anchors.fill: parent; onDismissed: shown = false }
    LangMenu { id: langMenu; anchors.fill: parent; onDismissed: shown = false }

    LogsPage {
        id: logs
        property bool showing: false
        width: parent.width; height: parent.height
        x: showing ? 0 : parent.width
        visible: x < parent.width
        Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        function openFor(id) { open(id); showing = true }
        onClosed: showing = false
    }

    Toast { id: toast; anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: Theme.s(54) }
}
