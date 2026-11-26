import QtQuick

// Turns the codes produced by logic.js / Backend into translated text.
// (Singletons and library JS cannot reach the package's translation catalogue, regular components can.)
QtObject {
    function status(info) {
        switch (info.key) {
        case "running": return i18nc("container state", "Running")
        case "starting": return i18nc("container state", "Starting")
        case "unhealthy": return i18nc("container state", "Unhealthy")
        case "restarting": return i18nc("container state", "Restarting")
        case "paused": return i18nc("container state", "Paused")
        case "exited": return i18nc("container state, %1 is the exit code", "Exited %1", info.code)
        case "stopped": return i18nc("container state", "Stopped")
        case "created": return i18nc("container state", "Created")
        default: return info.raw || ""
        }
    }
    // a compact duration such as 3d, 9h, 12s
    function span(n, u) {
        switch (u) {
        case "s": return i18nc("short duration, seconds", "%1s", n)
        case "m": return i18nc("short duration, minutes", "%1m", n)
        case "h": return i18nc("short duration, hours", "%1h", n)
        case "d": return i18nc("short duration, days", "%1d", n)
        case "w": return i18nc("short duration, weeks", "%1w", n)
        case "mo": return i18nc("short duration, months", "%1mo", n)
        case "y": return i18nc("short duration, years", "%1y", n)
        default: return i18nc("short duration, less than a second", "now")
        }
    }
    function hasSince(info) { return !!info.sinceU }
    function since(info) { return span(info.sinceN, info.sinceU) }
    function sinceAgo(info) { return i18nc("%1 is a short duration such as 3d", "%1 ago", since(info)) }
    function ago(epochSec) {
        var d = Math.max(0, Date.now() / 1000 - epochSec)
        if (d < 90) return i18nc("relative time", "just now")
        if (d < 5400) return i18nc("relative time, minutes", "%1m ago", Math.round(d / 60))
        if (d < 129600) return i18nc("relative time, hours", "%1h ago", Math.round(d / 3600))
        if (d < 86400 * 45) return i18nc("relative time, days", "%1d ago", Math.round(d / 86400))
        if (d < 86400 * 400) return i18nc("relative time, months", "%1mo ago", Math.round(d / 86400 / 30))
        return i18nc("relative time, years", "%1y ago", Math.round(d / 86400 / 365))
    }
}
