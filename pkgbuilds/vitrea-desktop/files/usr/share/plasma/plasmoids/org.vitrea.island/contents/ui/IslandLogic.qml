// What the island shows, and for how long. Pure QtQuick so it can be tested and recorded.
// Feed it "nowMs" (a clock) and events; read "mode".
//   baseline:  clock  ->  music (compact)  ->  timer (compact, wins over music)
//   popup (shown for a few seconds, then back to the baseline):
//              musicWide (new track), notify, volume, brightness, charging, timerDone
import QtQuick

QtObject {
    id: logic
    property real nowMs: 0

    // ---- inputs ----
    property bool musicActive: false
    property string musicTitle: ""

    // ---- popup pop-ups ----
    property string popup: ""
    property real popupUntil: 0
    property var info: ({})
    function show(kind, data, ms) {
        info = data || ({})
        popup = kind
        popupUntil = nowMs + (ms || 3500)
    }
    function dismiss() { popup = "" }

    // ---- timer ----
    property real timerEnd: 0
    property real timerTotal: 0
    readonly property bool timerRunning: timerEnd > 0
    readonly property real timerLeft: timerRunning ? Math.max(0, (timerEnd - nowMs) / 1000) : 0
    readonly property real timerFrac: timerRunning && timerTotal > 0 ? timerLeft / timerTotal : 0
    signal timerDone
    function startTimer(sec) { timerTotal = sec; timerEnd = nowMs + sec * 1000 }
    function cancelTimer() { timerEnd = 0 }
    function fmt(sec) {
        sec = Math.ceil(sec)
        var h = Math.floor(sec / 3600), m = Math.floor((sec % 3600) / 60), s = sec % 60
        return (h > 0 ? h + ":" + (m < 10 ? "0" : "") : "") + m + ":" + (s < 10 ? "0" : "") + s
    }

    onNowMsChanged: {
        if (popup !== "" && nowMs >= popupUntil) popup = ""
        if (timerEnd > 0 && nowMs >= timerEnd) {
            timerEnd = 0
            show("timerDone", {}, 6000)
            timerDone()
        }
    }
    // a new track (or music starting) opens the island wide for a moment
    onMusicTitleChanged: if (musicActive && musicTitle !== "") show("musicWide", {}, 5000)
    onMusicActiveChanged: if (musicActive && musicTitle !== "") show("musicWide", {}, 5000)

    readonly property string baseline: timerRunning ? "timer" : (musicActive ? "music" : "clock")
    readonly property string mode: popup !== "" ? popup : baseline
}
