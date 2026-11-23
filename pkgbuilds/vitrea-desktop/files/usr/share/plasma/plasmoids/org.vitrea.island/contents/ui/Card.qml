// Vitrea Island, expanded: cover art, track, live waveform, progress with times and transport.
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
    signal previous
    signal playPause
    signal next
    signal output
    implicitWidth: 420
    implicitHeight: active ? 236 : 128

    function fmt(sec) {
        sec = Math.max(0, Math.round(sec))
        var m = Math.floor(sec / 60), s = sec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // transport buttons drawn as shapes (emoji glyphs vary by font)
    component Glyph: Item {
        id: g
        property string kind: "play"     // back, fwd, play, pause, speaker
        property real size: 30
        signal clicked
        width: size * 1.6; height: size * 1.4
        scale: ma.pressed ? 0.86 : (ma.containsMouse ? 1.1 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
        onKindChanged: cv.requestPaint()
        Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.rgba(1, 1, 1, ma.containsMouse ? 0.10 : 0) }
        Canvas {
            id: cv
            anchors.centerIn: parent
            width: g.size; height: g.size
            onPaint: {
                var c = getContext("2d"), w = width, h = height
                c.reset(); c.fillStyle = "white"; c.strokeStyle = "white"; c.lineJoin = "round"
                function tri(x0, dir) {   // a triangle of width w/2 pointing left (-1) or right (+1)
                    c.beginPath()
                    if (dir > 0) { c.moveTo(x0, h * 0.2); c.lineTo(x0 + w * 0.46, h * 0.5); c.lineTo(x0, h * 0.8) }
                    else { c.moveTo(x0 + w * 0.46, h * 0.2); c.lineTo(x0, h * 0.5); c.lineTo(x0 + w * 0.46, h * 0.8) }
                    c.closePath(); c.fill()
                }
                if (g.kind === "fwd") { tri(w * 0.04, 1); tri(w * 0.5, 1) }
                else if (g.kind === "back") { tri(w * 0.04, -1); tri(w * 0.5, -1) }
                else if (g.kind === "play") { c.beginPath(); c.moveTo(w * 0.24, h * 0.12); c.lineTo(w * 0.86, h * 0.5); c.lineTo(w * 0.24, h * 0.88); c.closePath(); c.fill() }
                else if (g.kind === "pause") { c.fillRect(w * 0.22, h * 0.14, w * 0.18, h * 0.72); c.fillRect(w * 0.60, h * 0.14, w * 0.18, h * 0.72) }
                else if (g.kind === "speaker") {
                    c.beginPath(); c.moveTo(w * 0.08, h * 0.38); c.lineTo(w * 0.28, h * 0.38); c.lineTo(w * 0.52, h * 0.16)
                    c.lineTo(w * 0.52, h * 0.84); c.lineTo(w * 0.28, h * 0.62); c.lineTo(w * 0.08, h * 0.62); c.closePath(); c.fill()
                    c.lineWidth = w * 0.08; c.lineCap = "round"
                    c.beginPath(); c.arc(w * 0.52, h * 0.5, w * 0.2, -0.8, 0.8); c.stroke()
                    c.beginPath(); c.arc(w * 0.52, h * 0.5, w * 0.36, -0.8, 0.8); c.stroke()
                }
            }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: g.clicked() }
    }

    Rectangle {
        anchors.fill: parent
        radius: 34
        color: "#f5000000"
        border.color: Qt.rgba(1, 1, 1, 0.10)
    }

    // ---- something playing ----
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 22
        spacing: 14
        visible: card.active

        RowLayout {
            spacing: 16
            Rectangle {
                Layout.preferredWidth: 72; Layout.preferredHeight: 72; radius: 16
                color: Qt.rgba(card.accent.r, card.accent.g, card.accent.b, 0.3); clip: true
                Image { anchors.fill: parent; source: card.art; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                Text { anchors.centerIn: parent; text: "♪"; color: "white"; font.pixelSize: 34; visible: card.art == "" }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 2
                Text { Layout.fillWidth: true; text: card.title; color: "#f6f6ff"; elide: Text.ElideRight; font.family: "Inter"; font.pixelSize: 19; font.weight: Font.DemiBold }
                Text { Layout.fillWidth: true; text: card.artist; color: "#8e93b0"; elide: Text.ElideRight; font.family: "Inter"; font.pixelSize: 16 }
            }
            Wave { Layout.alignment: Qt.AlignTop; count: 6; barWidth: 3; maxHeight: 26; running: card.playing; accent: card.accent }
        }

        RowLayout {
            spacing: 12
            Text { text: card.fmt(card.position); color: "#8e93b0"; font.family: "Inter"; font.pixelSize: 12; Layout.preferredWidth: 34 }
            Rectangle {
                Layout.fillWidth: true; height: 6; radius: 3
                color: Qt.rgba(1, 1, 1, 0.22)
                Rectangle {
                    height: parent.height; radius: 3
                    width: card.length > 0 ? parent.width * Math.min(1, card.position / card.length) : 0
                    Behavior on width { NumberAnimation { duration: 900; easing.type: Easing.Linear } }
                    color: "#f2f2f8"
                }
            }
            Text { text: card.length > 0 ? "-" + card.fmt(card.length - card.position) : "--:--"; color: "#8e93b0"; font.family: "Inter"; font.pixelSize: 12; Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight }
        }

        Item {
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
    }

    // ---- nothing playing: a big clock ----
    ColumnLayout {
        anchors.centerIn: parent
        visible: !card.active
        spacing: 0
        Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(card.now, "HH:mm"); color: "#f4f4ff"; font.family: "Inter"; font.pixelSize: 46; font.weight: Font.Light }
        Text { Layout.alignment: Qt.AlignHCenter; text: Qt.formatDate(card.now, "dddd d MMMM") + "  ·  Nothing playing"; color: "#8e93b0"; font.family: "Inter"; font.pixelSize: 13 }
    }
}
