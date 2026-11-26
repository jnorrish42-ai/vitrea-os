// Vitrea Island: Plasma wrapper. The pill lives in the panel; clicking it opens the card.
// Data sources load independently, so a missing one (no battery, no brightness control) can't
// break the rest.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation

    // ---- music ----
    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property bool active: player !== null && player !== undefined
        && player.playbackStatus !== Mpris.PlaybackStatus.Stopped && (player.track || "") !== ""
    readonly property bool playing: active && player.playbackStatus === Mpris.PlaybackStatus.Playing

    // ---- clock + logic ----
    property date now: new Date()
    IslandLogic {
        id: logic
        musicActive: root.active
        musicTitle: root.active ? root.player.track : ""
        onTimerDone: if (chime.item) chime.item.play()
    }
    Timer {
        // fast ticks only while something on the island changes; once a second otherwise
        interval: (logic.popup !== "" || logic.timerRunning || root.expanded) ? 250 : 1000
        running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            root.now = new Date()
            logic.nowMs = root.now.getTime()
            if (root.playing && root.expanded) root.player.updatePosition()
        }
    }

    // ---- live sources ----
    Loader { id: volumeSrc; source: "sources/Volume.qml" }
    Connections { target: volumeSrc.item; function onChanged(level, muted) { logic.show("volume", { level: level, muted: muted }, 1800) } }
    Loader { id: brightSrc; source: "sources/Brightness.qml" }
    Connections { target: brightSrc.item; function onChanged(level) { logic.show("brightness", { level: level }, 1800) } }
    Loader { id: batterySrc; source: "sources/Battery.qml" }
    Connections { target: batterySrc.item; function onChanged(plugged, percent) { logic.show("charging", { plugged: plugged, percent: percent }, 3500) } }
    Loader { id: notifySrc; source: "sources/Notifications.qml" }
    Connections {
        target: notifySrc.item
        function onArrived(app, title, body, icon) { logic.show("notify", { app: app, title: title, body: body, icon: icon }, 5000) }
    }
    Loader { id: chime; source: "sources/Chime.qml" }

    // the expanded card closes itself after a while unless the mouse is on it
    Timer {
        id: autoClose
        interval: 10000
        running: root.expanded && !root.cardHovered
        onTriggered: root.expanded = false
    }
    property bool cardHovered: false

    compactRepresentation: Item {
        Layout.minimumWidth: pill.implicitWidth + 8
        Layout.preferredWidth: pill.implicitWidth + 8
        Layout.maximumWidth: pill.implicitWidth + 8
        Pill {
            id: pill
            anchors.centerIn: parent
            barHeight: Math.max(22, Math.min(parent.height - 6, 32))
            mode: logic.mode
            info: logic.info
            timeText: Qt.formatDate(root.now, "ddd d MMM") + "   " + Qt.formatTime(root.now, "HH:mm")
            playing: root.playing
            title: root.active ? root.player.track + (root.player.artist ? "  ·  " + root.player.artist : "") : ""
            art: root.active ? (root.player.artUrl || "") : ""
            timerText: logic.fmt(logic.timerLeft)
            timerFrac: logic.timerFrac
            accent: Kirigami.Theme.highlightColor
            notifIcon: Component { Kirigami.Icon { source: (pill.notifInfo.icon || "") !== "" ? pill.notifInfo.icon : "preferences-desktop-notification" } }
            onClicked: {
                if (logic.popup === "notify" || logic.popup === "timerDone") logic.dismiss()
                else root.expanded = !root.expanded
            }
        }
    }

    fullRepresentation: Card {
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        HoverHandler { onHoveredChanged: { root.cardHovered = hovered; if (!hovered) autoClose.restart() } }
        active: root.active
        playing: root.playing
        title: root.active ? root.player.track : ""
        artist: root.active ? (root.player.artist || root.player.identity || "") : ""
        art: root.active ? (root.player.artUrl || "") : ""
        now: root.now
        position: root.active ? root.player.position / 1000000 : 0
        length: root.active ? root.player.length / 1000000 : 0
        accent: Kirigami.Theme.highlightColor
        timerRunning: logic.timerRunning
        timerText: logic.fmt(logic.timerLeft)
        onOutput: KCMUtils.KCMLauncher.openSystemSettings("kcm_pulseaudio")
        onPrevious: root.player.Previous()
        onPlayPause: root.player.PlayPause()
        onNext: root.player.Next()
        onStartTimer: (seconds) => { logic.startTimer(seconds); root.expanded = false }
        onCancelTimer: logic.cancelTimer()
    }
}
