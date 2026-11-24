// Vitrea Music: a Liquid Glass "Now Playing" card. Invisible while nothing plays, it glides in
// when any player (Spotify, Firefox, Elisa, ...) starts, with art, title and glass controls.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.private.mpris as Mpris

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    Mpris.Mpris2Model { id: mpris }
    readonly property var player: mpris.currentPlayer
    readonly property bool playing: player !== null && player !== undefined && player.playbackStatus === Mpris.PlaybackStatus.Playing
    readonly property bool active: player !== null && player !== undefined
        && player.playbackStatus !== Mpris.PlaybackStatus.Stopped && (player.track || "") !== ""

    component GlassRound: Item {
        id: btn
        property string icon
        property real size: 40
        property bool primary: false
        signal clicked
        width: size; height: size
        scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.08 : 1)
        Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
        Rectangle {
            anchors.fill: parent; radius: width / 2
            color: btn.primary ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, ma.containsMouse ? 0.55 : 0.40)
                               : Qt.rgba(1, 1, 1, ma.containsMouse ? 0.18 : 0.10)
            border.color: Qt.rgba(1, 1, 1, ma.containsMouse ? 0.6 : 0.32)
            Behavior on color { ColorAnimation { duration: 160 } }
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
                height: parent.height * 0.46; radius: height / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.25) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                }
            }
        }
        Kirigami.Icon { anchors.centerIn: parent; width: btn.size * 0.48; height: width; source: btn.icon; color: "#ffffff"; isMask: true }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 18
        Layout.minimumHeight: Kirigami.Units.gridUnit * 6
        Layout.preferredWidth: Kirigami.Units.gridUnit * 24
        Layout.preferredHeight: Kirigami.Units.gridUnit * 8

        Item {
            id: card
            anchors.fill: parent
            opacity: root.active ? 1 : 0
            scale: root.active ? 1 : 0.94
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 520; easing.type: Easing.OutBack } }

            Rectangle {   // the glass card
                anchors.fill: parent
                radius: 26
                color: Qt.rgba(0.07, 0.07, 0.12, 0.42)
                border.color: Qt.rgba(1, 1, 1, 0.20)
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
                    height: parent.height * 0.45; radius: 25
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.13) }
                        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 16

                Rectangle {   // album art with rounded corners
                    Layout.preferredWidth: Math.min(card.height - 32, 120)
                    Layout.preferredHeight: Layout.preferredWidth
                    radius: 16
                    color: Qt.rgba(1, 1, 1, 0.08)
                    clip: true
                    Image {
                        id: art
                        anchors.fill: parent
                        source: root.player ? (root.player.artUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                        layer.enabled: true
                        layer.smooth: true
                    }
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.5; height: width
                        visible: !art.visible
                        source: root.player ? (root.player.iconName || "media-default-album") : "media-default-album"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Label {
                        Layout.fillWidth: true
                        text: root.player ? (root.player.track || "") : ""
                        color: "#f2f2f3"; font.pixelSize: 17; font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        text: root.player ? (root.player.artist || root.player.identity || "") : ""
                        color: Qt.rgba(0.9, 0.92, 1, 0.72); font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    Item { Layout.fillHeight: true }
                    RowLayout {
                        spacing: 12
                        GlassRound { icon: "media-skip-backward"; enabled: root.player && root.player.canGoPrevious; onClicked: root.player.Previous() }
                        GlassRound { icon: root.playing ? "media-playback-pause" : "media-playback-start"; size: 46; primary: true; onClicked: root.player.PlayPause() }
                        GlassRound { icon: "media-skip-forward"; enabled: root.player && root.player.canGoNext; onClicked: root.player.Next() }
                    }
                }
            }
        }
    }
}
