import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_socket: socket.text
    property alias cfg_cli: cli.text
    property alias cfg_terminal: terminal.text
    property alias cfg_interval: interval.value
    property alias cfg_backgroundInterval: background.value
    property alias cfg_notifications: notifications.checked
    property string cfg_socketDefault
    property string cfg_cliDefault
    property string cfg_terminalDefault
    property int cfg_intervalDefault
    property int cfg_backgroundIntervalDefault
    property bool cfg_notificationsDefault

    Kirigami.FormLayout {
        QQC2.TextField {
            id: socket
            Kirigami.FormData.label: i18n("Engine socket:")
            placeholderText: "auto"
        }
        QQC2.Label {
            text: i18n("“auto” finds Docker, rootless Docker and Podman. Or use a path such as /run/user/1000/podman/podman.sock.")
            wrapMode: Text.WordWrap
            Layout.maximumWidth: Kirigami.Units.gridUnit * 22
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: interval
            Kirigami.FormData.label: i18n("Refresh while open:")
            from: 2; to: 60
            textFromValue: value => i18n("%1 s", value)
        }
        QQC2.SpinBox {
            id: background
            Kirigami.FormData.label: i18n("Refresh in the background:")
            from: 5; to: 300
            textFromValue: value => i18n("%1 s", value)
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.TextField {
            id: cli
            Kirigami.FormData.label: i18n("Container CLI:")
            placeholderText: "docker"
        }
        QQC2.TextField {
            id: terminal
            Kirigami.FormData.label: i18n("Terminal command:")
            placeholderText: "konsole -e"
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.CheckBox {
            id: notifications
            Kirigami.FormData.label: i18n("Notifications:")
            text: i18n("Tell me when a container crashes, turns unhealthy or restart-loops")
        }
    }
}
