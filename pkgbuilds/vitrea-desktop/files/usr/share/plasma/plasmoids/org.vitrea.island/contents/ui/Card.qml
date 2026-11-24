// Vitrea Island, expanded: cover art, track, live waveform, progress with times and transport,
// plus quick timers. With nothing playing it shows a big clock.
import QtQuick
import QtQuick.Layouts

Item {
    id: card
    property bool playing: false
    property bool active: false
    property string title: ""
    property string artist: ""
    property url art: ""
    property real position: 0      // seconds
    property real length: 0        // seconds
    property date now: new Date()
    property color accent: "#cba6f7"
    // timer
    property bool timerRunning: false
    property string timerText: ""
    signal previous
    signal playPause
    signal next
    signal output
    signal startTimer(int seconds)
    signal cancelTimer
    implicitWidth: 420
    implicitHeight: col.implicitHeight + 44

    function fmt(sec) {
        sec = Math.max(0, Math.round(sec))
        var m = Math.floor(sec / 60), s = sec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    component Glyph: Item {
        id: g
        property string kind: "play"
        property real size: 30
        signal clicked
        width: size * 1.6; height: size * 1.4
        scale: ma.pressed ? 0.86 : (ma.containsMouse ? 1.1 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
        Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.rgba(1, 1, 1, ma.containsMouse ? 0.10 : 0) }
        GlyphIcon { anchors.centerIn: parent; width: g.size; height: g.size; kind: g.kind }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: g.clicked() }
    }
    component Chip: Item {
        id: chip
        property string text
        property bool danger: false
        signal clicked
        implicitWidth: lbl.implicitWidth + 30; implicitHeight: 32
        scale: cm.pressed ? 0.92 : (cm.containsMouse ? 1.05 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
        Rectangle {
            anchors.fill: parent; radius: height / 2
            color: chip.danger ? Qt.rgba(1, 0.35, 0.35, cm.containsMouse ? 0.32 : 0.22) : Qt.rgba(1, 1, 1, cm.containsMouse ? 0.18 : 0.10)
            border.color: Qt.rgba(1, 1, 1, 0.22)
        }
        Text { id: lbl; anchors.centerIn: parent; text: chip.text; color: "#f4f4f5"; font.family: "Inter"; font.pixelSize: 13; font.weight: Font.DemiBold }
        MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
    }

    Rectangle {
        anchors.fill: parent
        radius: 34
        color: "#f5000000"
        border.color: Qt.rgba(1, 1, 1, 0.10)
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 22 }
        spacing: 14

        // ---- something playing ----
        RowLayout {
            visible: card.active
            spacing: 16
            Item {
                Layout.preferredWidth: 72; Layout.preferredHeight: 72
                Rectangle { anchors.fill: parent; radius: 20; color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.3) }
                RoundedImage { anchors.fill: parent; radius: 20; source: card.art }
                Text { anchors.centerIn: parent; text: "♪"; color: "white"; font.pixelSize: 34; visible: card.art == "" }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; text: card.title; color: "#f6f6f7"; elide: Text.ElideRight; font.family: "Inter"; font.pixelSize: 19; font.weight: Font.DemiBold }
                Text { Layout.fillWidth: true; text: card.artist; color: "#9a9a9f"; elide: Text.ElideRight; font.family: "Inter"; font.pixelSize: 16 }
            }
            Wave { Layout.alignment: Qt.AlignTop; count: 6; barWidth: 3; maxHeight: 26; running: card.playing; accent: card.accent }
        }
        RowLayout {
            visible: card.active
            spacing: 12
            Text { text: card.fmt(card.position); color: "#9a9a9f"; font.family: "Inter"; font.pixelSize: 12; Layout.preferredWidth: 34 }
            Rectangle {
                Layout.fillWidth: true; height: 6; radius: 3
                color: Qt.rgba(1, 1, 1, 0.22)
                Rectangle {
                    height: parent.height; radius: 3
                    width: card.length > 0 ? parent.width * Math.min(1, card.position / card.length) : 0
                    color: "#f2f2f3"
                }
            }
            Text { text: card.length > 0 ? "-" + card.fmt(card.length - card.position) : "--:--"; color: "#9a9a9f"; font.family: "Inter"; font.pixelSize: 12; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
        }
        Item {
            visible: card.active
            Layout.fillWidth: true; Layout.preferredHeight: 44
            Row {
                anchors.centerIn: parent
                spacing: 26
                Glyph { kind: "back"; size: 28; onClicked: card.previous() }
                Glyph { kind: card.playing ? "pause" : "play"; size: 30; onClicked: card.playPause() }
                Glyph { kind: "fwd"; size: 28; onClicked: card.next() }
            }
            Glyph { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; kind: "speaker"; size: 20; onClicked: card.output() }
        }

        // ---- nothing playing: a big clock ----
        ColumnLayout {
            visible: !card.active
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(card.now, "HH:mm"); color: "#f4f4f5"; font.family: "Inter"; font.pixelSize: 46; font.weight: Font.Light }
            Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatDate(card.now, "dddd d MMMM") + "  ·  Nothing playing"; color: "#9a9a9f"; font.family: "Inter"; font.pixelSize: 13 }
        }

        // ---- timer ----
        Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }
        RowLayout {
            spacing: 10
            GlyphIcon { kind: "timer"; color: card.timerRunning ? card.accent : "#9a9a9f"; Layout.preferredWidth: 20; Layout.preferredHeight: 20 }
            Text {
                visible: card.timerRunning
                text: card.timerText
                color: card.accent; font.family: "Inter"; font.pixelSize: 20; font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
            Text { visible: !card.timerRunning; text: "Timer"; color: "#9a9a9f"; font.family: "Inter"; font.pixelSize: 14 }
            Item { Layout.fillWidth: true }
            Repeater {
                model: card.timerRunning ? [] : [1, 5, 10, 25]
                Chip { required property int modelData; text: modelData + " min"; onClicked: card.startTimer(modelData * 60) }
            }
            Chip { visible: card.timerRunning; text: "Cancel"; danger: true; onClicked: card.cancelTimer() }
        }
    }
}
