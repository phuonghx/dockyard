import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "logic.js" as L

// Logs open in place of the list (a page, not a modal): selectable, level-coloured, live.
Rectangle {
    id: p
    property string cid: ""
    property int tail: 300
    property bool follow: true
    property bool loading: false
    property string raw: ""
    property string html: ""
    property string failure: ""
    property bool truncated: false
    signal closed()

    color: Theme.surface
    readonly property var c: { Backend.revision; return Backend.cmap[cid] || null }
    readonly property var st: c ? L.statusInfo(c) : ({ tone: "idle", label: "" })

    function open(id) { cid = id; raw = ""; html = ""; failure = ""; follow = true; load() }
    function load() {
        if (!cid) return
        loading = true
        Backend.logs(cid, tail, d => {
            loading = false
            if (!d.ok) { failure = d.message || "Could not read logs."; return }
            failure = ""
            truncated = d.truncated
            if (d.text === raw) return
            raw = d.text
            html = L.logHtml(d.text, { bad: Theme.bad.toString(), warn: Theme.warn.toString(), dim: Theme.tx3.toString() })
            if (follow) Qt.callLater(p.toEnd)
        })
    }
    function toEnd() { flick.contentY = Math.max(0, flick.contentHeight - flick.height) }
    onTailChanged: if (visible) load()

    Timer { interval: 2000; repeat: true; running: p.visible && p.follow && p.c && p.c.state === "running"; onTriggered: p.load() }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.s(52)
            color: Theme.shell
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.s(8); rightMargin: Theme.s(10) }
                spacing: Theme.s(8)
                IconButton { symbol: "back"; tip: "Back to containers"; onClicked: p.closed(); Keys.onEscapePressed: p.closed() }
                StatusDot { tone: p.st.tone }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.s(1)
                    Txt { Layout.fillWidth: true; text: p.c ? p.c.name : "Container removed"; kind: "head"; strong: true; elide: Text.ElideRight }
                    Txt { text: "Logs · last " + p.tail + " lines" + (p.truncated ? " (trimmed)" : ""); kind: "tiny"; color: Theme.tx3 }
                }
                Chip { text: "100"; clickable: true; selected: p.tail === 100; onClicked: p.tail = 100; tone: p.tail === 100 ? "accent" : "neutral" }
                Chip { text: "300"; clickable: true; selected: p.tail === 300; onClicked: p.tail = 300; tone: p.tail === 300 ? "accent" : "neutral" }
                Chip { text: "1000"; clickable: true; selected: p.tail === 1000; onClicked: p.tail = 1000; tone: p.tail === 1000 ? "accent" : "neutral" }
                IconButton { symbol: "copy"; tip: "Copy all"; onClicked: { Backend.copy(p.raw) } }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.line }
        }

        // body
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flick
                anchors { fill: parent; margins: Theme.s(2) }
                contentWidth: width
                contentHeight: body.height + Theme.s(24)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                onMovementStarted: if (contentY < contentHeight - height - 24) p.follow = false
                QQC2.ScrollBar.vertical: ThemedScrollBar {}

                TextEdit {
                    id: body
                    x: Theme.s(14); y: Theme.s(12)
                    width: flick.width - Theme.s(28)
                    readOnly: true
                    selectByMouse: true
                    textFormat: TextEdit.RichText
                    wrapMode: TextEdit.WrapAnywhere
                    text: p.html
                    color: Theme.tx2
                    font.family: Theme.mono
                    font.pixelSize: Theme.fs(11)
                    selectionColor: Theme.alpha(Theme.acc, 0.35)
                    selectedTextColor: Theme.tx
                    Accessible.role: Accessible.StaticText
                    Accessible.name: "Container logs"
                }
            }

            EmptyState {
                anchors.fill: parent
                visible: !p.loading && p.failure === "" && p.raw === ""
                icon: "logs"; title: "Nothing logged yet"
                body: "This container hasn't written anything to stdout or stderr."
            }
            EmptyState {
                anchors.fill: parent
                visible: p.failure !== ""
                icon: "warning"; tone: "bad"; title: "Couldn't read the logs"; body: p.failure
            }
        }

        // footer: follow switch
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.s(40)
            color: Theme.shell
            Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.line }
            RowLayout {
                anchors { fill: parent; leftMargin: Theme.s(12); rightMargin: Theme.s(10) }
                Txt { text: p.loading ? "Refreshing…" : (p.follow ? "Following new output" : "Paused"); kind: "tiny"; color: Theme.tx3; Layout.fillWidth: true }
                IconButton {
                    symbol: p.follow ? "pause" : "play"
                    label: p.follow ? "Pause" : "Follow"
                    tone: p.follow ? "neutral" : "accent"
                    onClicked: { p.follow = !p.follow; if (p.follow) { p.load(); p.toEnd() } }
                }
                IconButton { symbol: "refresh"; tip: "Refresh now"; busy: p.loading; onClicked: p.load() }
            }
        }
    }
}
