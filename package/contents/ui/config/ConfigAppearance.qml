import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property string cfg_theme
    property string cfg_language
    property string cfg_languageDefault
    property string cfg_themeDefault
    property alias cfg_grouped: grouped.checked
    property alias cfg_defaultTab: tabBox.currentIndex
    property int cfg_defaultTabDefault
    property alias cfg_showCount: showCount.checked
    property bool cfg_showCountDefault
    property bool cfg_groupedDefault

    readonly property var modes: ["auto", "dark", "light"]
    readonly property var langCodes: ["auto", "en", "vi", "es", "fr", "de", "pt_BR", "ru", "ja", "zh_CN"]

    Kirigami.FormLayout {
        QQC2.ComboBox {
            id: langBox
            Kirigami.FormData.label: i18n("Language:")
            model: [i18n("Automatic (system language)"), "English", "Tiếng Việt", "Español", "Français", "Deutsch", "Português (Brasil)", "Русский", "日本語", "简体中文"]
            currentIndex: Math.max(0, langCodes.indexOf(cfg_language))
            onActivated: index => cfg_language = langCodes[index]
        }
        QQC2.ComboBox {
            id: theme
            Kirigami.FormData.label: i18n("Theme:")
            model: [i18n("Follow the Plasma colour scheme"), i18n("Always dark (harbour at night)"), i18n("Always light")]
            currentIndex: Math.max(0, modes.indexOf(cfg_theme))
            onActivated: index => cfg_theme = modes[index]
        }
        QQC2.ComboBox {
            id: tabBox
            Kirigami.FormData.label: i18n("Open on:")
            model: [i18n("Containers"), i18n("Images"), i18n("Volumes"), i18n("Networks")]
        }
        QQC2.CheckBox {
            id: grouped
            Kirigami.FormData.label: i18n("Containers:")
            text: i18n("Group by Compose project")
        }
        QQC2.CheckBox {
            id: showCount
            Kirigami.FormData.label: i18n("Panel icon:")
            text: i18n("Show the running count next to the icon")
        }
    }
}
