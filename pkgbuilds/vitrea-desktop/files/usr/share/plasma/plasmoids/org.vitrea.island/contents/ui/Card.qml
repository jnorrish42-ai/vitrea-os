// Vitrea Island, expanded form: a glass card with art, track info and glass controls.
import QtQuick
import QtQuick.Layouts

Item {
    id: card
    property bool playing: false
    property bool active: false
    property string title: ""
    property string artist: ""
    property url art: ""
    property date now: new Date()
    property color accent: "#cba6f7"
    signal previous
    signal playPause
    signal next
    implicitWidth: 380
    implicitHeight: active ? 150 : 120

    component RoundButton: Item {
        id: rb
        property string glyph
        property real size: 40
        property bool primary: false
        signal clicked
        width: size; height: size
        scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.08 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
        Rectangle {
            anchors.fill: parent; radius: width / 2
            color: rb.primary ? Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.5) : Qt.rgba(1, 1, 1, ma.containsMouse ? 0.18 : 0.10)
            border.color: Qt.rgba(1, 1, 1, 0.3)
        }
        Text { anchors.centerIn: parent; text: rb.glyph; color: "white"; font.pixelSize: rb.size * 0.42 }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; onClicked: rb.clicked() }
    }

    Rectangle {
        anchors.fill: parent
        radius: 30
        color: "#f2000000"
        border.color: Qt.rgba(1, 1, 1, 0.12)
    }

    // something playing
    RowLayout {
        anchors.fill: parent; anchors.margins: 18
        spacing: 16
        visible: card.active
        Rectangle {
            Layout.preferredWidth: 96; Layout.preferredHeight: 96; radius: 20
            color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.3); clip: true
            Image { anchors.fill: parent; source: card.art; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
            Text { anchors.centerIn: parent; text: "♪"; color: "white"; font.pixelSize: 44; visible: card.art == "" }
        }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 2
            Text { Layout.fillWidth: true; text: card.title; color: "#f4f4ff"; elide: Text.ElideRight; font.family: "Inter"; font.pixelSize: 17; font.weight: Font.DemiBold }
            Text { Layout.fillWidth: true; text: card.artist; color: "#9aa0c0"; elide: Text.ElideRight; font.family: "Inter"; font.pixelSize: 13 }
            Item { Layout.fillHeight: true }
            RowLayout {
                spacing: 12
                RoundButton { glyph: "⏮"; onClicked: card.previous() }
                RoundButton { glyph: card.playing ? "⏸" : "▶"; size: 46; primary: true; onClicked: card.playPause() }
                RoundButton { glyph: "⏭"; onClicked: card.next() }
            }
        }
    }

    // nothing playing: a big clock + date
    ColumnLayout {
        anchors.centerIn: parent
        visible: !card.active
        spacing: 0
        Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(card.now, "HH:mm"); color: "#f4f4ff"; font.family: "Inter"; font.pixelSize: 44; font.weight: Font.Light }
        Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatDate(card.now, "dddd d MMMM") + "  ·  Nothing playing"; color: "#9aa0c0"; font.family: "Inter"; font.pixelSize: 13 }
    }
}
