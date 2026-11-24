// A row of level bars that dance while playing, coloured accent -> pink -> blue.
import QtQuick

Row {
    id: wave
    property int count: 7
    property real barWidth: 3
    property real maxHeight: 18
    property bool running: true
    property color accent: "#cba6f7"
    spacing: barWidth * 0.9
    height: maxHeight

    function mix(a, b, t) { return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1) }
    readonly property var stops: [accent, Qt.lighter(accent, 1.3), accent]

    Repeater {
        model: wave.count
        Rectangle {
            required property int index
            readonly property real t: wave.count > 1 ? index / (wave.count - 1) : 0
            width: wave.barWidth; radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: t < 0.5 ? wave.mix(wave.stops[0], wave.stops[1], t * 2) : wave.mix(wave.stops[1], wave.stops[2], (t - 0.5) * 2)
            property real level: 0.25 + 0.5 * Math.abs(Math.sin(index * 1.7))
            height: Math.max(wave.barWidth, wave.maxHeight * level)
            SequentialAnimation on level {
                running: wave.running; loops: Animation.Infinite
                NumberAnimation { to: 0.95; duration: 230 + (index * 53) % 170; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.2 + (index % 3) * 0.12; duration: 260 + (index * 37) % 150; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.7; duration: 210 + (index * 71) % 190; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.35; duration: 250; easing.type: Easing.InOutSine }
            }
        }
    }
}
