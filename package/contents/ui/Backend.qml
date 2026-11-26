pragma Singleton
import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "logic.js" as L

// The single source of truth for the widget: polls the helper, keeps lookup maps
// for the delegates, and exposes every action. State changes bump 'revision' so
// delegates re-read their record without the list being rebuilt.
QtObject {
    id: be

    // ---- settings (pushed in from main.qml)
    property string socketPath: "auto"
    property string cli: "docker"
    property string terminal: "konsole -e"
    property bool notify: true
    property bool active: false

    readonly property string scriptPath: decodeURIComponent(Qt.resolvedUrl("../scripts/dockyard.py").toString().replace("file://", ""))

    // ---- state
    property bool loaded: false
    property bool refreshing: false
    property bool manual: false          // true only for a refresh the user asked for
    property string errorKind: ""
    property string errorMessage: ""
    property string errorHint: ""
    property var engine: ({})
    property var containers: []
    property var ordered: []
    property var images: []
    property var volumes: []
    property var networks: []
    property var cmap: ({})
    property var imap: ({})
    property var vmap: ({})
    property var nmap: ({})
    property var df: null
    property var inspectCache: ({})
    property var pending: ({})
    property int revision: 0
    property string expandedId: ""
    property var cpuHistory: []
    property var memHistory: []
    property real cpuCores: 0
    property real memUsed: 0
    property var tally: ({ total: 0, running: 0, attention: 0, stopped: 0, paused: 0 })

    signal toast(string text, string tone)
    signal alert(string title, string body)
    signal copyRequested(string text)
    function copy(text) { copyRequested(text) }

    // ---- plumbing
    function q(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }
    property int _seq: 0
    property var _cb: ({})
    property var _exec: P5Support.DataSource {
        engine: "executable"
        connectedSources: []
        onNewData: (src, data) => {
            const cb = be._cb[src]
            delete be._cb[src]
            disconnectSource(src)
            if (cb) cb(data["exit code"], data["stdout"] || "", data["stderr"] || "")
        }
    }

    function sh(cmd, cb) {
        const key = cmd + " #" + (++_seq)
        if (cb) _cb[key] = cb
        _exec.connectSource(key)
    }

    function helper(args, cb) {
        sh("python3 " + q(scriptPath) + " --socket " + q(socketPath || "auto") + " " + args, (code, out, err) => {
            let d
            try { d = JSON.parse(out) } catch (e) {
                d = { ok: false, error: "internal", hint: "Dockyard needs python3 (it ships with Fedora).",
                      message: (err || out || "The helper returned nothing.").trim().slice(0, 300) }
            }
            cb(d)
        })
    }

    // ---- polling
    property double _started: 0
    function refresh(byUser) {
        if (refreshing && Date.now() - _started < 30000) return
        refreshing = true
        manual = !!byUser
        _started = Date.now()
        helper("snapshot", d => { refreshing = false; manual = false; apply(d) })
    }

    function apply(d) {
        if (!d.ok) {
            errorKind = d.error || "internal"
            errorMessage = d.message || ""
            errorHint = d.hint || ""
            containers = []; ordered = []; images = []; volumes = []; networks = []
            cmap = {}; imap = {}; vmap = {}; nmap = {}
            tally = L.counts([])
            loaded = true
            revision++
            return
        }
        const wasLoaded = loaded && errorKind === ""
        const old = cmap
        const map = {}
        d.containers.forEach(c => { map[c.id] = c })
        if (wasLoaded && notify) {
            d.containers.forEach(c => {
                const o = old[c.id]
                if (!o || pending[c.id]) return
                if (o.state === "running" && c.state === "exited" && L.statusInfo(c).attention)
                    alert(c.name + " stopped unexpectedly", L.statusInfo(c).label + " · " + c.image)
                else if (c.health === "unhealthy" && o.health !== "unhealthy")
                    alert(c.name + " is unhealthy", "Health checks are failing · " + c.image)
                else if (c.state === "restarting" && o.state !== "restarting")
                    alert(c.name + " is restart-looping", c.image)
            })
        }
        errorKind = ""; errorMessage = ""; errorHint = ""
        engine = d.engine
        containers = d.containers
        ordered = L.manifestOrder(d.containers)
        images = d.images; volumes = d.volumes; networks = d.networks
        cmap = map
        const m2 = {}; d.images.forEach(i => { m2[i.id] = i }); imap = m2
        const m3 = {}; d.volumes.forEach(v => { m3[v.id] = v }); vmap = m3
        const m4 = {}; d.networks.forEach(n => { m4[n.id] = n }); nmap = m4
        tally = L.counts(d.containers)

        let cpu = 0, mem = 0
        d.containers.forEach(c => { cpu += c.cpu; mem += c.mem })
        cpuCores = cpu / 100
        memUsed = mem
        const hc = cpuHistory.slice(-59); hc.push(cpuCores); cpuHistory = hc
        const hm = memHistory.slice(-59); hm.push(mem); memHistory = hm
        loaded = true
        revision++
    }

    function fetchDf() {
        helper("df", d => { if (d.ok) { df = d; revision++ } })
    }

    function inspect(cid) {
        if (inspectCache[cid] && Date.now() - inspectCache[cid]._at < 15000) return
        helper("inspect " + q(cid), d => {
            if (!d.ok) return
            d._at = Date.now()
            const c = Object.assign({}, inspectCache); c[cid] = d; inspectCache = c
            revision++
        })
    }

    // ---- actions
    readonly property var _past: ({ start: "Started", stop: "Stopped", restart: "Restarted", pause: "Paused",
                                    unpause: "Resumed", kill: "Killed", rm: "Removed" })

    function _mark(ids, action) {
        const p = Object.assign({}, pending)
        ids.forEach(i => { if (action) p[i] = action; else delete p[i] })
        pending = p
        revision++
    }

    function act(action, ids) {
        if (!ids.length) return
        _mark(ids, action)
        helper("act " + action + " " + ids.map(q).join(" "), d => {
            _mark(ids, "")
            if (d.results && !d.ok) {
                const bad = d.results.filter(r => !r.ok)[0]
                toast(bad ? bad.message : "That didn't work", "bad")
            } else if (!d.ok) toast(d.message || "That didn't work", "bad")
            else {
                const who = ids.length === 1 && cmap[ids[0]] ? cmap[ids[0]].name : ids.length + " containers"
                toast(_past[action] + " " + who, "ok")
            }
            refresh()
        })
    }

    function removeResource(kind, id, label) {
        helper(kind + " " + q(id), d => {
            if (d.ok) toast("Removed " + label, "ok"); else toast(d.message || "Could not remove " + label, "bad")
            refresh(); fetchDf()
        })
    }

    function prune(what) {
        helper("prune " + what, d => {
            if (d.ok) toast(d.freed > 0 ? "Reclaimed " + L.fmtBytes(d.freed) : "Nothing to clean", "ok")
            else toast(d.message || "Cleanup failed", "bad")
            refresh(); fetchDf()
        })
    }

    function logs(cid, tail, cb) { helper("logs " + q(cid) + " " + tail, cb) }

    function openTerminal(cid) {
        sh("setsid -f " + terminal + " " + cli + " exec -it " + q(cid)
           + " sh -c 'command -v bash >/dev/null 2>&1 && exec bash || exec sh'", null)
    }

    function startEngine() {
        toast("Asking systemd to start Docker…", "info")
        sh("pkexec systemctl start docker", (code, out, err) => {
            if (code === 0) { toast("Docker is up", "ok"); refresh() }
            else toast("Could not start Docker" + (err ? ": " + err.trim().slice(0, 80) : ""), "bad")
        })
    }
}
