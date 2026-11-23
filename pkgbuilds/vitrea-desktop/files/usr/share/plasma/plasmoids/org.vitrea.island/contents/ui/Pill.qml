// Vitrea Island, compact form: a black pill that springs wider when something plays.
import QtQuick

Item {
    id: pill
    property string timeText: ""
    property bool playing: false
    property bool active: false          // a player has a track (playing or paused)
    property string title: ""
    property url art: ""
    property color accent: "#cba6f7"
    property real barHeight: 28
    signal clicked

    readonly property real wideWidth: Math.min(400, 150 + titleText.implicitWidth)
    implicitWidth: active ? wideWidth : timeLabel.implicitWidth + 34
    implicitHeight: barHeight
    Behavior on implicitWidth { SpringAnimation { spring: 3.2; damping: 0.32; epsilon: 0.25 } }

    Rectangle {
        id: body
        anchors.centerIn: parent
        width: pill.implicitWidth
        height: pill.barHeight - (area.pressed ? 3 : 0)
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        radius: height / 2
        color: "#ec000000"
        border.color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.22 : 0.10)
        Behavior on border.color { ColorAnimation { duration: 160 } }
        clip: true

        // idle: the time
        Text {
            id: timeLabel
            anchors.centerIn: parent
            text: pill.timeText
            color: "#f4f4ff"
            font.family: "Inter"; font.pixelSize: Math.round(pill.barHeight * 0.5); font.weight: Font.DemiBold
            opacity: pill.active ? 0 : 1
            scale: pill.active ? 0.8 : 1
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        }

        // playing: art · title · bars
        Item {
            anchors.fill: parent
            anchors.leftMargin: 4; anchors.rightMargin: 12
            opacity: pill.active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

            Rectangle {
                id: artBox
                width: body.height - 8; height: width; radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Qt.rgba(pill.accent.r, pill.accent.g, pill.accent.b, 0.35)
                clip: true
                Image { anchors.fill: parent; source: pill.art; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                Text { anchors.centerIn: parent; text: "♪"; color: "white"; font.pixelSize: parent.height * 0.6; visible: pill.art == "" }
                RotationAnimation on rotation { from: 0; to: 360; duration: 9000; loops: Animation.Infinite; running: pill.playing }
            }
            Text {
                id: titleText
                anchors.left: artBox.right; anchors.leftMargin: 10
                anchors.right: bars.left; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: pill.title
                elide: Text.ElideRight
                color: "#f4f4ff"
                font.family: "Inter"; font.pixelSize: Math.round(pill.barHeight * 0.46); font.weight: Font.Medium
            }
            Wave {
                id: bars
                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                count: 7; barWidth: 3; maxHeight: body.height * 0.62
                running: pill.playing; accent: pill.accent
            }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }
}
