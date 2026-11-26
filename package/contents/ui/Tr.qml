import QtQuick

// Turns the codes produced by logic.js / Backend into translated text.
// (Singletons and library JS cannot reach the package's translation catalogue, regular components can.)
QtObject {
    function status(info) {
        switch (info.key) {
        case "running": return L10n.tc("container state", "Running")
        case "starting": return L10n.tc("container state", "Starting")
        case "unhealthy": return L10n.tc("container state", "Unhealthy")
        case "restarting": return L10n.tc("container state", "Restarting")
        case "paused": return L10n.tc("container state", "Paused")
        case "exited": return L10n.tc("container state, %1 is the exit code", "Exited %1", info.code)
        case "stopped": return L10n.tc("container state", "Stopped")
        case "created": return L10n.tc("container state", "Created")
        default: return info.raw || ""
        }
    }
    // a compact duration such as 3d, 9h, 12s
    function span(n, u) {
        switch (u) {
        case "s": return L10n.tc("short duration, seconds", "%1s", n)
        case "m": return L10n.tc("short duration, minutes", "%1m", n)
        case "h": return L10n.tc("short duration, hours", "%1h", n)
        case "d": return L10n.tc("short duration, days", "%1d", n)
        case "w": return L10n.tc("short duration, weeks", "%1w", n)
        case "mo": return L10n.tc("short duration, months", "%1mo", n)
        case "y": return L10n.tc("short duration, years", "%1y", n)
        default: return L10n.tc("short duration, less than a second", "now")
        }
    }
    function hasSince(info) { return !!info.sinceU }
    function since(info) { return span(info.sinceN, info.sinceU) }
    function sinceAgo(info) { return L10n.tc("%1 is a short duration such as 3d", "%1 ago", since(info)) }
    function ago(epochSec) {
        var d = Math.max(0, Date.now() / 1000 - epochSec)
        if (d < 90) return L10n.tc("relative time", "just now")
        if (d < 5400) return L10n.tc("relative time, minutes", "%1m ago", Math.round(d / 60))
        if (d < 129600) return L10n.tc("relative time, hours", "%1h ago", Math.round(d / 3600))
        if (d < 86400 * 45) return L10n.tc("relative time, days", "%1d ago", Math.round(d / 86400))
        if (d < 86400 * 400) return L10n.tc("relative time, months", "%1mo ago", Math.round(d / 86400 / 30))
        return L10n.tc("relative time, years", "%1y ago", Math.round(d / 86400 / 365))
    }
}
