// Vitrea login splash: the same calm scene as the boot splash (logo on a dark background,
// a thin line filling as Plasma loads). KSplash sets "stage" as the desktop starts.
import QtQuick

Rectangle {
    id: root
    property int stage
    color: "#111112"

    Image {
        id: logo
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.height * 0.05
        source: "images/logo-240.png"
        width: 120; height: 120
        sourceSize: Qt.size(240, 240)
        smooth: true
        opacity: 0
        OpacityAnimator on opacity { from: 0; to: 1; duration: 700; easing.type: Easing.InOutQuad }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: logo.bottom
        anchors.topMargin: 48
        width: 180; height: 2
        color: Qt.rgba(1, 1, 1, 0.16)
        Rectangle {
            width: parent.width * Math.min(1, root.stage / 6)
            height: parent.height
            color: Qt.rgba(1, 1, 1, 0.85)
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
        }
    }
}
