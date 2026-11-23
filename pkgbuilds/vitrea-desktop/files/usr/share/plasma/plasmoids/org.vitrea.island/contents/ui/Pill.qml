// Vitrea Island in the top bar: one black pill that springs between modes.
//   clock · music (compact) · musicWide · timer · timerDone · notify · volume · brightness · charging
import QtQuick

Item {
    id: pill
    property string mode: "clock"
    property real barHeight: 28
    property color accent: "#cba6f7"
    // clock
    property string timeText: ""
    // music
    property bool playing: false
    property string title: ""
    property url art: ""
    // timer
    property string timerText: ""
    property real timerFrac: 0
    // transients: notify {app, title, body, icon}, volume/brightness {level, muted}, charging {plugged, percent}
    property var info: ({})
    property Component notifIcon: null      // optional: draws the notification icon (e.g. a themed icon in Plasma)
    signal clicked

    // each pop-up keeps its own copy of its data, so one fading out never shows the next one's data
    property var lvlInfo: ({})
    property var notifInfo: ({})
    property var chargeInfo: ({})
    function cacheInfo() {
        if (mode === "volume" || mode === "brightness") lvlInfo = info
        else if (mode === "notify") notifInfo = info
        else if (mode === "charging") chargeInfo = info
    }
    onInfoChanged: cacheInfo()
    onModeChanged: cacheInfo()

    readonly property real h: barHeight
    readonly property real fontPx: Math.round(h * 0.47)

    // width per mode
    readonly property real targetWidth: {
        switch (mode) {
        case "music": return h * 4.4
        case "musicWide": return Math.min(420, h * 2.2 + titleText.implicitWidth + h * 2.4)
        case "timer": return h * 1.4 + timerLabel.implicitWidth + h * 0.9
        case "timerDone": return h * 1.4 + doneLabel.implicitWidth + h * 0.9
        case "notify": return Math.min(560, h * 1.6 + notifText.implicitWidth + h * 0.8)
        case "volume": case "brightness": return h * 9
        case "charging": return h * 1.4 + chargeLabel.implicitWidth + h * 0.9
        default: return timeLabel.implicitWidth + h * 1.2
        }
    }
    implicitWidth: targetWidth
    implicitHeight: h
    Behavior on implicitWidth { SpringAnimation { spring: 3.2; damping: 0.32; epsilon: 0.25 } }

    component Part: Item {
        property string forMode
        property var modes: [forMode]
        readonly property bool on: modes.indexOf(pill.mode) >= 0
        anchors.fill: parent
        opacity: on ? 1 : 0
        scale: on ? 1 : 0.86
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }

    Rectangle {
        id: body
        anchors.centerIn: parent
        width: pill.implicitWidth
        height: pill.h - (area.pressed ? 3 : 0)
        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        radius: height / 2
        color: "#ee000000"
        border.color: pill.mode === "timerDone" ? Qt.rgba(pill.accent.r, pill.accent.g, pill.accent.b, 0.9)
                    : Qt.rgba(1, 1, 1, area.containsMouse ? 0.22 : 0.10)
        Behavior on border.color { ColorAnimation { duration: 160 } }
        clip: true

        // ---- clock ----
        Part {
            forMode: "clock"
            Text {
                id: timeLabel
                anchors.centerIn: parent
                text: pill.timeText
                color: "#f4f4ff"; font.family: "Inter"; font.pixelSize: pill.fontPx; font.weight: Font.DemiBold
            }
        }

        // ---- music: compact (art · waveform) and wide (art · title · waveform) ----
        Part {
            modes: ["music", "musicWide"]
            Item {
                id: artBox
                x: 4; anchors.verticalCenter: parent.verticalCenter
                width: body.height - 8; height: width
                Rectangle { anchors.fill: parent; radius: width / 2; color: Qt.rgba(pill.accent.r, pill.accent.g, pill.accent.b, 0.35) }
                RoundedImage { anchors.fill: parent; radius: width / 2; source: pill.art }
                Text { anchors.centerIn: parent; text: "♪"; color: "white"; font.pixelSize: parent.height * 0.6; visible: pill.art == "" }
                RotationAnimation on rotation { from: 0; to: 360; duration: 9000; loops: Animation.Infinite; running: pill.playing }
            }
            Text {
                id: titleText
                anchors.left: artBox.right; anchors.leftMargin: 10
                anchors.right: wave.left; anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: pill.title
                elide: Text.ElideRight
                opacity: pill.mode === "musicWide" ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                color: "#f4f4ff"; font.family: "Inter"; font.pixelSize: pill.fontPx - 1; font.weight: Font.Medium
            }
            Wave {
                id: wave
                anchors.right: parent.right; anchors.rightMargin: pill.h * 0.4
                anchors.verticalCenter: parent.verticalCenter
                count: 6; barWidth: 3; maxHeight: body.height * 0.6
                running: pill.playing; accent: pill.accent
            }
        }

        // ---- timer ----
        Part {
            forMode: "timer"
            Canvas {
                id: ring
                x: pill.h * 0.3; anchors.verticalCenter: parent.verticalCenter
                width: pill.h * 0.66; height: width
                property real frac: pill.timerFrac
                onFracChanged: requestPaint()
                onPaint: {
                    var c = getContext("2d"), r = width / 2 - 2
                    c.reset(); c.lineWidth = 3; c.lineCap = "round"
                    c.strokeStyle = Qt.rgba(1, 1, 1, 0.18); c.beginPath(); c.arc(width / 2, height / 2, r, 0, Math.PI * 2); c.stroke()
                    c.strokeStyle = pill.accent; c.beginPath(); c.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * frac); c.stroke()
                }
            }
            Text {
                id: timerLabel
                anchors.left: ring.right; anchors.leftMargin: pill.h * 0.3; anchors.verticalCenter: parent.verticalCenter
                text: pill.timerText
                color: pill.accent; font.family: "Inter"; font.pixelSize: pill.fontPx; font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }

        // ---- timer finished ----
        Part {
            forMode: "timerDone"
            GlyphIcon {
                id: bell
                x: pill.h * 0.34; anchors.verticalCenter: parent.verticalCenter
                width: pill.h * 0.62; height: width; kind: "bell"; color: pill.accent
                SequentialAnimation on rotation {
                    running: pill.mode === "timerDone"; loops: Animation.Infinite
                    NumberAnimation { to: 18; duration: 90 } NumberAnimation { to: -18; duration: 180 }
                    NumberAnimation { to: 12; duration: 150 } NumberAnimation { to: 0; duration: 120 }
                    PauseAnimation { duration: 500 }
                }
            }
            Text {
                id: doneLabel
                anchors.left: bell.right; anchors.leftMargin: pill.h * 0.3; anchors.verticalCenter: parent.verticalCenter
                text: "Time's up"
                color: "#f4f4ff"; font.family: "Inter"; font.pixelSize: pill.fontPx; font.weight: Font.DemiBold
            }
        }

        // ---- notification ----
        Part {
            forMode: "notify"
            Item {
                id: nIcon
                x: pill.h * 0.22; anchors.verticalCenter: parent.verticalCenter
                width: pill.h * 0.72; height: width
                Loader { anchors.fill: parent; sourceComponent: pill.notifIcon; active: pill.notifIcon !== null }
                Rectangle {
                    anchors.fill: parent; radius: width * 0.28; visible: pill.notifIcon === null
                    color: pill.accent
                    Text { anchors.centerIn: parent; text: (pill.notifInfo.app || "•").charAt(0).toUpperCase(); color: "black"; font.pixelSize: parent.height * 0.6; font.weight: Font.Bold }
                }
            }
            Text {
                id: notifText
                anchors.left: nIcon.right; anchors.leftMargin: pill.h * 0.32
                anchors.right: parent.right; anchors.rightMargin: pill.h * 0.5
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                textFormat: Text.StyledText
                text: "<b>" + (pill.notifInfo.title || pill.notifInfo.app || "") + "</b>" + ((pill.notifInfo.body || "") !== "" ? "  <font color='#a9aed0'>" + pill.notifInfo.body + "</font>" : "")
                color: "#f4f4ff"; font.family: "Inter"; font.pixelSize: pill.fontPx - 1
            }
        }

        // ---- volume / brightness ----
        Part {
            modes: ["volume", "brightness"]
            GlyphIcon {
                id: lvlIcon
                x: pill.h * 0.36; anchors.verticalCenter: parent.verticalCenter
                width: pill.h * 0.58; height: width
                kind: pill.mode === "brightness" ? "sun" : (pill.lvlInfo.muted || pill.lvlInfo.level === 0 ? "muted" : "speaker")
            }
            Rectangle {
                id: track
                anchors.left: lvlIcon.right; anchors.leftMargin: pill.h * 0.36
                anchors.right: pct.left; anchors.rightMargin: pill.h * 0.3
                anchors.verticalCenter: parent.verticalCenter
                height: pill.h * 0.22; radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.2)
                Rectangle {
                    height: parent.height; radius: parent.radius
                    width: parent.width * Math.max(0, Math.min(1, pill.lvlInfo.muted ? 0 : (pill.lvlInfo.level || 0)))
                    Behavior on width { SpringAnimation { spring: 4; damping: 0.4; epsilon: 0.25 } }
                    color: "#f4f4ff"
                }
            }
            Text {
                id: pct
                anchors.right: parent.right; anchors.rightMargin: pill.h * 0.45; anchors.verticalCenter: parent.verticalCenter
                width: pill.h * 1.3; horizontalAlignment: Text.AlignRight
                text: pill.lvlInfo.muted ? "Off" : Math.round((pill.lvlInfo.level || 0) * 100) + "%"
                color: "#a9aed0"; font.family: "Inter"; font.pixelSize: pill.fontPx - 2; font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }
        }

        // ---- charging ----
        Part {
            forMode: "charging"
            GlyphIcon {
                id: chargeIcon
                x: pill.h * 0.34; anchors.verticalCenter: parent.verticalCenter
                width: pill.h * 0.64; height: width
                kind: pill.chargeInfo.plugged ? "bolt" : "battery"
                fill: (pill.chargeInfo.percent || 0) / 100
                color: pill.chargeInfo.plugged ? "#7ee787" : ((pill.chargeInfo.percent || 0) <= 20 ? "#ff6b6b" : "#f4f4ff")
            }
            Text {
                id: chargeLabel
                anchors.left: chargeIcon.right; anchors.leftMargin: pill.h * 0.3; anchors.verticalCenter: parent.verticalCenter
                textFormat: Text.StyledText
                text: (pill.chargeInfo.plugged ? "Charging" : "On battery") + "  <font color='" + (pill.chargeInfo.plugged ? "#7ee787" : "#a9aed0") + "'>" + (pill.chargeInfo.percent || 0) + "%</font>"
                color: "#f4f4ff"; font.family: "Inter"; font.pixelSize: pill.fontPx; font.weight: Font.DemiBold
            }
        }

        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }
}
