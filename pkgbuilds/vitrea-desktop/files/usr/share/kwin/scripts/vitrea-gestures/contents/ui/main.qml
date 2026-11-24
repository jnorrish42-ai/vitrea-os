// Vitrea touchpad gestures, on top of Plasma's own (three- or four-finger swipe left/right
// switches desktops, four-finger swipe up shows all windows):
//   pinch four fingers together -> show all windows (Overview); pinch again to go back
import QtQuick
import org.kde.kwin

Item {
    DBusCall {
        id: overview
        service: "org.kde.kglobalaccel"
        path: "/component/kwin"
        dbusInterface: "org.kde.kglobalaccel.Component"
        method: "invokeShortcut"
        arguments: ["Overview"]
    }
    PinchGestureHandler {
        direction: PinchGestureHandler.Direction.Contracting
        fingerCount: 4
        onActivated: overview.call()
    }
}
