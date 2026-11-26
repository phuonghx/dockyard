pragma Singleton
import QtQuick
import "translations.js" as D

// The widget's own translator. KDE's i18n() always follows the system language and cannot reach
// singletons, but users should be able to pick a language in the widget. So the UI asks L10n.
// Bindings that call these functions re-evaluate when 'lang' changes, so switching is instant.
QtObject {
    id: l

    property string lang: "auto"      // "auto" or one of 'codes'

    readonly property var codes: ["en", "vi", "es", "fr", "de", "pt_BR", "ru", "ja", "zh_CN"]
    // each language is always shown in its own name, so it can be found even when the UI is unreadable
    readonly property var names: ({ en: "English", vi: "Tiếng Việt", es: "Español", fr: "Français", de: "Deutsch",
                                    pt_BR: "Português (Brasil)", ru: "Русский", ja: "日本語", zh_CN: "简体中文" })

    // the language actually in use
    readonly property string active: {
        if (lang !== "auto" && codes.indexOf(lang) >= 0) return lang
        const ui = Qt.locale().uiLanguages || []
        for (let i = 0; i < ui.length; i++) {
            const c = String(ui[i]).replace("-", "_")
            if (codes.indexOf(c) >= 0) return c
            const base = c.split("_")[0]
            if (base === "pt") return "pt_BR"
            if (base === "zh") return "zh_CN"
            if (codes.indexOf(base) >= 0) return base
        }
        return "en"
    }

    function _forms(ctx, msg) {
        const d = D.data[active]
        return d ? (d[(ctx || "") + "\n" + msg] || null) : null
    }
    function _fmt(s, args) {
        return s.replace(/%(\d+)/g, function (m, n) { const v = args[parseInt(n) - 1]; return v === undefined ? m : v })
    }
    function _plural(n) {
        switch (active) {
        case "es": case "de": return n !== 1 ? 1 : 0
        case "fr": case "pt_BR": return n > 1 ? 1 : 0
        case "ru": return (n % 10 === 1 && n % 100 !== 11) ? 0 : ((n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) ? 1 : 2)
        case "vi": case "ja": case "zh_CN": return 0
        default: return n !== 1 ? 1 : 0
        }
    }

    // t("Text %1", a)  /  tc("context", "Text")  /  tn("%1 file", "%1 files", n)
    function t(msg) {
        const f = _forms("", msg)
        return _fmt(f ? f[0] : msg, Array.prototype.slice.call(arguments, 1))
    }
    function tc(ctx, msg) {
        const f = _forms(ctx, msg)
        return _fmt(f ? f[0] : msg, Array.prototype.slice.call(arguments, 2))
    }
    function tn(one, many, n) {
        const f = _forms("", one)
        const text = f ? (f[_plural(n)] || f[f.length - 1]) : (n === 1 ? one : many)
        return _fmt(text, [n].concat(Array.prototype.slice.call(arguments, 3)))
    }
}
