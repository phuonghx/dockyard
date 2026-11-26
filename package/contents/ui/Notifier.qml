import QtQuick
import org.kde.notification

// Loaded on demand so a missing KNotifications QML module can never break the widget.
Item {
    function send(title, body) {
        const n = factory.createObject(this, { title: title, text: body })
        n.sendEvent()
        destroy(8000)
    }
    Component {
        id: factory
        Notification {
            componentName: "plasma_workspace"
            eventId: "notification"
            iconName: "dockyard"
            urgency: Notification.HighUrgency
            autoDelete: true
        }
    }
}
