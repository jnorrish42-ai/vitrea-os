// New notifications (Plasma's notification server).
import QtQuick
import org.kde.notificationmanager as NM

Item {
    id: src
    signal arrived(string app, string title, string body, string icon)
    property bool ready: false
    Timer { interval: 3000; running: true; onTriggered: src.ready = true }
    NM.Notifications {
        id: notes
        showNotifications: true
        showJobs: false
        showExpired: false
        showDismissed: false
        sortMode: NM.Notifications.SortByDate
        sortOrder: Qt.DescendingOrder
        groupMode: NM.Notifications.GroupDisabled
    }
    Connections {
        target: notes
        function onRowsInserted(parent, first, last) {
            if (!src.ready) return
            var i = notes.index(first, 0)
            var body = String(notes.data(i, NM.Notifications.BodyRole) || "").replace(/<[^>]*>/g, "").replace(/\s+/g, " ")
            src.arrived(String(notes.data(i, NM.Notifications.ApplicationNameRole) || ""),
                        String(notes.data(i, NM.Notifications.SummaryRole) || ""), body,
                        String(notes.data(i, NM.Notifications.ApplicationIconNameRole) || notes.data(i, NM.Notifications.IconNameRole) || ""))
        }
    }
}
