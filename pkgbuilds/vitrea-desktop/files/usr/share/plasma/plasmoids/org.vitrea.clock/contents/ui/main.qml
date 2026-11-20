// Vitrea Clock: big thin numerals (stacked like a poster, or on one line) with a soft accent glow.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground | PlasmaCore.Types.ConfigurableBackground
    preferredRepresentation: fullRepresentation

    property date now: new Date()
    readonly property bool stacked: Plasmoid.configuration.stacked
    readonly property string hours: Qt.formatTime(now, Plasmoid.configuration.use24h ? "HH" : "h")
    readonly property string minutes: Qt.formatTime(now, "mm")

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 8
        Layout.minimumHeight: Kirigami.Units.gridUnit * 8
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        Layout.preferredHeight: Kirigami.Units.gridUnit * 16

        Item {
            id: face
            anchors.fill: parent
            layer.enabled: Plasmoid.configuration.glow
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Kirigami.Theme.highlightColor
                shadowBlur: 1.0
                shadowOpacity: 0.55
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: -numeral.font.pixelSize * 0.22

                Text {
                    id: numeral
                    Layout.alignment: Qt.AlignRight
                    text: root.stacked ? root.hours : root.hours + ":" + root.minutes
                    color: "#f2f4ff"
                    font.family: "Inter"
                    font.weight: Font.ExtraLight
                    font.pixelSize: Math.min(face.height / (root.stacked ? 2.6 : 1.6), face.width / (root.stacked ? 1.25 : 2.6))
                    font.letterSpacing: -font.pixelSize * 0.04
                    renderType: Text.QtRendering
                }
                Text {
                    visible: root.stacked
                    Layout.alignment: Qt.AlignRight
                    text: root.minutes
                    color: "#f2f4ff"
                    font: numeral.font
                    renderType: Text.QtRendering
                }
                Text {
                    visible: Plasmoid.configuration.showDate
                    Layout.alignment: Qt.AlignRight
                    Layout.topMargin: numeral.font.pixelSize * 0.32
                    text: Qt.formatDate(root.now, "dddd, d MMMM")
                    color: Qt.rgba(0.95, 0.96, 1, 0.82)
                    font.family: "Inter"
                    font.pixelSize: Math.max(13, numeral.font.pixelSize * 0.13)
                    font.letterSpacing: 1
                    renderType: Text.QtRendering
                }
            }
        }
    }
}
