import QtQuick
import QtQuick.Layouts
import "logic.js" as L

// "Free up space": every clean-up says what it removes and how much it should free,
// and asks twice before it does anything.
Item {
    id: p
    property bool shown: false
    property string armed: ""
    signal dismissed()

    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.base } }
    onShownChanged: { armed = ""; if (shown) Backend.fetchDf() }

    readonly property var df: { Backend.revision; return Backend.df }
    property var entries: []
    property string _ek: ""
    on_EntriesNowChanged: {
        const k = JSON.stringify(_entriesNow)
        if (k !== _ek) { _ek = k; entries = _entriesNow }
    }
    readonly property var _entriesNow: {
        Backend.revision
        const imgs = Backend.images, vols = Backend.volumes
        const dangling = imgs.filter(i => i.dangling && i.used === 0)
        const unusedImgs = imgs.filter(i => i.used === 0)
        const anon = vols.filter(v => v.anonymous && v.used === 0)
        const stopped = Backend.containers.filter(c => c.state === "exited" || c.state === "dead" || c.state === "created")
        const sum = a => a.reduce((s, i) => s + i.size, 0)
        return [
            { key: "containers", title: L10n.t("Stopped containers"), note: L10n.t("Removes exited and created containers"), n: stopped.length, size: df ? df.containersReclaimable : 0 },
            { key: "images", title: L10n.t("Dangling images"), note: L10n.t("Untagged layers nothing refers to"), n: dangling.length, size: sum(dangling) },
            { key: "images-all", title: L10n.t("All unused images"), note: L10n.t("Any image no container uses, tagged or not"), n: unusedImgs.length, size: sum(unusedImgs) },
            { key: "volumes", title: L10n.t("Anonymous volumes"), note: L10n.t("Unnamed volumes no container uses. Named volumes stay."), n: anon.length, size: df ? anon.reduce((s, v) => s + Math.max(0, (df.volumeSizes[v.name] || 0)), 0) : 0, risky: true },
            { key: "builder", title: L10n.t("Build cache"), note: L10n.t("Cached layers from docker build"), n: df && df.cacheReclaimable > 0 ? 1 : 0, size: df ? df.cacheReclaimable : 0 }
        ]
    }

    MouseArea { anchors.fill: parent; onClicked: p.dismissed() }
    Rectangle { anchors.fill: parent; color: Theme.alpha("#000000", Theme.dark ? 0.55 : 0.25) }

    Rectangle {
        id: sheet
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: col.implicitHeight + Theme.s(28)
        color: Theme.raised
        radius: Theme.s(14)
        border.width: 1; border.color: Theme.lineStrong

        MouseArea { anchors.fill: parent }  // swallow clicks

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s(14) }
            spacing: Theme.s(4)

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: Theme.s(6)
                Glyph { name: "broom"; size: Theme.s(16); color: Theme.acc }
                Txt { text: L10n.t("Free up space"); kind: "head"; strong: true; Layout.fillWidth: true }
                IconButton { symbol: "close"; tip: L10n.t("Close"); onClicked: p.dismissed() }
            }

            Repeater {
                model: p.entries
                delegate: Rectangle {
                    id: item
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.s(52)
                    radius: Theme.s(9)
                    color: ih.hovered ? Theme.alpha(Theme.tx, 0.05) : "transparent"
                    HoverHandler { id: ih }
                    readonly property bool armedHere: p.armed === modelData.key

                    RowLayout {
                        anchors { fill: parent; leftMargin: Theme.s(10); rightMargin: Theme.s(8) }
                        spacing: Theme.s(10)
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.s(2)
                            Txt { text: modelData.title + (modelData.n ? "  ·  " + modelData.n : ""); kind: "small"; strong: true; elide: Text.ElideRight; Layout.fillWidth: true }
                            Txt { text: item.armedHere && modelData.risky ? L10n.t("This deletes their data for good.") : modelData.note; kind: "tiny"
                                  color: item.armedHere && modelData.risky ? Theme.bad : Theme.tx3; elide: Text.ElideRight; Layout.fillWidth: true }
                        }
                        Txt { text: modelData.size > 0 ? L.fmtBytes(modelData.size) : "—"; kind: "monoSm"; color: modelData.size > 0 ? Theme.tx : Theme.tx3 }
                        IconButton {
                            label: item.armedHere ? L10n.t("Confirm") : L10n.t("Clean")
                            armed: item.armedHere
                            tone: "accent"
                            enabled: modelData.n > 0
                            onClicked: {
                                if (item.armedHere) { p.armed = ""; Backend.prune(modelData.key); p.dismissed() }
                                else { p.armed = modelData.key; armTimer.restart() }
                            }
                        }
                    }
                }
            }
        }
        Timer { id: armTimer; interval: 3500; onTriggered: p.armed = "" }
    }
}
