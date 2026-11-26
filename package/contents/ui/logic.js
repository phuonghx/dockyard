.pragma library
// Pure helpers: formatting, state vocabulary, list building. No QML types in here.

function fmtBytes(n) {
    if (!n || n < 0) return "0 B"
    var u = ["B", "KB", "MB", "GB", "TB"], i = 0
    while (n >= 1024 && i < u.length - 1) { n /= 1024; i++ }
    return (n >= 100 || i === 0 ? Math.round(n) : n.toFixed(n >= 10 ? 0 : 1)) + " " + u[i]
}

function fmtCores(pct) {
    var c = pct / 100
    return c < 0.095 ? c.toFixed(2) : c.toFixed(1)
}

function fmtPct(p) { return p >= 10 ? Math.round(p) + "%" : p.toFixed(1) + "%" }

function compactSpan(text) {
    // "3 days" -> "3d", "About an hour" -> "1h", "Less than a second" -> "now"
    var s = (text || "").toLowerCase().replace("about an ", "1 ").replace("about a ", "1 ").replace(/^an? /, "1 ")
    if (s.indexOf("less than") === 0) return "now"
    var m = /(\d+)\s*(second|minute|hour|day|week|month|year)/.exec(s)
    if (!m) return ""
    return m[1] + { second: "s", minute: "m", hour: "h", day: "d", week: "w", month: "mo", year: "y" }[m[2]]
}

function ago(epochSec) {
    var d = Math.max(0, Date.now() / 1000 - epochSec)
    if (d < 90) return "just now"
    if (d < 5400) return Math.round(d / 60) + "m ago"
    if (d < 129600) return Math.round(d / 3600) + "h ago"
    if (d < 86400 * 45) return Math.round(d / 86400) + "d ago"
    if (d < 86400 * 400) return Math.round(d / 86400 / 30) + "mo ago"
    return Math.round(d / 86400 / 365) + "y ago"
}

// One vocabulary for every container state. tone drives colour, shape and copy.
function statusInfo(c) {
    var st = c.status || "", s = c.state
    var m
    if (s === "running") {
        m = /^Up (.*?)(?: \(|$)/.exec(st)
        var up = m ? compactSpan(m[1]) : ""
        if (c.health === "unhealthy") return { tone: "bad", label: "Unhealthy", since: up, attention: true }
        if (c.health === "starting") return { tone: "info", label: "Starting", since: up, attention: false }
        return { tone: "run", label: "Running", since: up, attention: false }
    }
    if (s === "restarting") {
        m = /\) (.*?) ago/.exec(st)
        return { tone: "bad", label: "Restarting", since: m ? compactSpan(m[1]) : "", attention: true }
    }
    if (s === "paused") return { tone: "warn", label: "Paused", since: "", attention: false }
    if (s === "exited" || s === "dead") {
        m = /Exited \((-?\d+)\) (.*?) ago/.exec(st)
        var code = m ? parseInt(m[1]) : 0
        var when = m ? compactSpan(m[2]) : ""
        if (code !== 0) return { tone: "fail", label: "Exited " + code, since: when, attention: true }
        return { tone: "idle", label: "Stopped", since: when, attention: false }
    }
    if (s === "created") return { tone: "idle", label: "Created", since: "", attention: false }
    return { tone: "idle", label: s || "Unknown", since: "", attention: false }
}

var NOT_WEB = { 22: 1, 25: 1, 1433: 1, 3306: 1, 5432: 1, 5433: 1, 5672: 1, 6379: 1, 9092: 1, 11211: 1, 27017: 1 }
function isWebPort(p) { return !NOT_WEB[p] }

function splitImage(ref) {
    // "ghcr.io/acme/app:1.2" -> {name:"acme/app", tag:"1.2"}
    var s = ref || "", tag = "latest"
    var at = s.indexOf("@"); if (at > 0) s = s.slice(0, at)
    var i = s.lastIndexOf(":")
    if (i > s.lastIndexOf("/")) { tag = s.slice(i + 1); s = s.slice(0, i) }
    var parts = s.split("/")
    if (parts.length > 1 && (parts[0].indexOf(".") >= 0 || parts[0].indexOf(":") >= 0)) parts.shift()
    return { name: parts.join("/"), tag: tag }
}

function matches(q, fields) {
    if (!q) return true
    for (var i = 0; i < fields.length; i++) if ((fields[i] || "").toLowerCase().indexOf(q) >= 0) return true
    return false
}

function sortKey(c) { return ((c.project || "~") + "|" + c.name).toLowerCase() }

function manifestOrder(list) {
    return list.slice().sort(function (a, b) { var x = sortKey(a), y = sortKey(b); return x < y ? -1 : x > y ? 1 : 0 })
}

// Up to six tones for the brand mark, worst first, so trouble is visible even at 22px.
function markTones(list) {
    var rank = { bad: 0, fail: 1, warn: 2, info: 3, run: 4, idle: 5 }
    return list.map(function (c) { return statusInfo(c).tone })
        .sort(function (a, b) { return rank[a] - rank[b] }).slice(0, 6)
}

function counts(list) {
    var r = { total: list.length, running: 0, attention: 0, stopped: 0, paused: 0 }
    list.forEach(function (c) {
        if (statusInfo(c).attention) r.attention++
        if (c.state === "running") r.running++
        else if (c.state === "paused") r.paused++
        else if (c.state !== "restarting") r.stopped++
    })
    return r
}

// Flat items for the list: group headers + rows, keyed so the ListModel can be patched in place.
function containerView(list, o) {
    var q = (o.query || "").trim().toLowerCase()
    var rows = list.filter(function (c) {
        var s = statusInfo(c)
        if (o.filter === "running" && c.state !== "running") return false
        if (o.filter === "attention" && !s.attention) return false
        if (o.filter === "stopped" && (c.state === "running" || c.state === "paused" || c.state === "restarting")) return false
        var ports = c.ports.map(function (p) { return ":" + p.pub }).join(" ")
        return matches(q, [c.name, c.image, c.project, c.service, ports, s.label])
    })
    rows = manifestOrder(rows)
    var items = []
    function row(c) { return { key: "c:" + c.id, kind: "row", rid: c.id, label: "", count: 0, running: 0, collapsed: false } }
    if (!o.group) { rows.forEach(function (c) { items.push(row(c)) }); return items }
    var groups = {}, order = []
    rows.forEach(function (c) {
        var g = c.project || ""
        if (!groups[g]) { groups[g] = []; order.push(g) }
        groups[g].push(c)
    })
    order.sort(function (a, b) { return a === "" ? 1 : b === "" ? -1 : (a < b ? -1 : 1) })
    order.forEach(function (g) {
        var members = groups[g]
        var collapsed = !!(o.collapsed && o.collapsed[g]) && !q
        items.push({ key: "g:" + g, kind: "header", rid: g, label: g || "Standalone", count: members.length,
                     running: members.filter(function (c) { return c.state === "running" }).length, collapsed: collapsed })
        if (!collapsed) members.forEach(function (c) { items.push(row(c)) })
    })
    return items
}

function resourceView(list, o, fields) {
    var q = (o.query || "").trim().toLowerCase()
    var out = list.filter(function (r) {
        if (o.unusedOnly && r.used > 0) return false
        return matches(q, fields(r))
    })
    function nm(r) { return r.name || (r.tags && r.tags[0]) || r.id }
    out.sort(function (a, b) { return nm(a) < nm(b) ? -1 : 1 })
    return out.map(function (r) { return { key: "r:" + r.id, kind: "row", rid: r.id, label: "", count: 0, running: 0, collapsed: false } })
}

// Write a row only when something in it really changed: ListModel.set() on identical data
// still signals a change, which makes the view rebuild delegates and lose its scroll position.
function patch(model, i, it) {
    var cur = model.get(i)
    for (var f in it) if (cur[f] !== it[f]) { model.set(i, it); return }
}

// Patch a ListModel to match items (by key) without resetting delegates, scroll or hover.
function syncModel(model, items) {
    var want = {}
    items.forEach(function (it) { want[it.key] = true })
    for (var i = model.count - 1; i >= 0; i--) if (!want[model.get(i).key]) model.remove(i)
    for (var j = 0; j < items.length; j++) {
        var it = items[j]
        if (j < model.count && model.get(j).key === it.key) { patch(model, j, it); continue }
        var found = -1
        for (var k = j + 1; k < model.count; k++) if (model.get(k).key === it.key) { found = k; break }
        if (found >= 0) { model.move(found, j, 1); patch(model, j, it) } else model.insert(j, it)
    }
}

function escapeHtml(s) { return s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;") }

// Log text -> rich text with level colouring. Colours are passed in so the log follows the theme.
function logHtml(text, colors) {
    var lines = text.split("\n")
    if (lines.length && lines[lines.length - 1] === "") lines.pop()
    return lines.map(function (ln) {
        var e = escapeHtml(ln).replace(/^( +)/, function (m) { return new Array(m.length + 1).join("&nbsp;") })
        var col = ""
        if (/\b(error|fatal|panic|exception|critical|failed?)\b/i.test(ln)) col = colors.bad
        else if (/\bwarn(ing)?\b/i.test(ln)) col = colors.warn
        else if (/^\s+at |^\s+File "|^Traceback/.test(ln)) col = colors.dim
        return col ? "<span style=\"color:" + col + "\">" + e + "</span>" : e
    }).join("<br>")
}
