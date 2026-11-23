// Vitrea Island: Plasma wrapper. The pill lives in the panel; clicking it opens the card.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris
import org.kde.kcmutils as KCMUtils

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: compactRepresentation

    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property bool active: player !== null && player !== undefined
        && player.playbackStatus !== Mpris.PlaybackStatus.Stopped && (player.track || "") !== ""
    readonly property bool playing: active && player.playbackStatus === Mpris.PlaybackStatus.Playing
    property date now: new Date()
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: { root.now = new Date(); if (root.playing && root.expanded) root.player.updatePosition() }
    }

    compactRepresentation: Item {
        Layout.minimumWidth: pill.implicitWidth + 8
        Layout.preferredWidth: pill.implicitWidth + 8
        Layout.maximumWidth: pill.implicitWidth + 8
        Pill {
            id: pill
            anchors.centerIn: parent
            barHeight: Math.max(22, Math.min(parent.height - 6, 32))
            timeText: Qt.formatDate(root.now, "ddd d MMM") + "   " + Qt.formatTime(root.now, "HH:mm")
            active: root.active
            playing: root.playing
            title: root.active ? root.player.track + (root.player.artist ? "  ·  " + root.player.artist : "") : ""
            art: root.active ? (root.player.artUrl || "") : ""
            accent: Kirigami.Theme.highlightColor
            onClicked: root.expanded = !root.expanded
        }
    }

    fullRepresentation: Card {
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        active: root.active
        playing: root.playing
        title: root.active ? root.player.track : ""
        artist: root.active ? (root.player.artist || root.player.identity || "") : ""
        art: root.active ? (root.player.artUrl || "") : ""
        now: root.now
        position: root.active ? root.player.position / 1000000 : 0
        length: root.active ? root.player.length / 1000000 : 0
        accent: Kirigami.Theme.highlightColor
        onOutput: KCMUtils.KCMLauncher.openSystemSettings("kcm_pulseaudio")
        onPrevious: root.player.Previous()
        onPlayPause: root.player.PlayPause()
        onNext: root.player.Next()
    }
}
