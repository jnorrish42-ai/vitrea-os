// Vitrea Welcome: three steps, in the system's own style.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: win
    width: 640
    height: 560
    minimumWidth: 520
    minimumHeight: 480
    visible: true
    title: "Welcome to Vitrea"

    component Step: RowLayout {
        property int number
        property string heading
        property string detail
        property alias buttonText: action.text
        property alias buttonIcon: action.icon.name
        signal triggered
        Layout.fillWidth: true
        spacing: Kirigami.Units.largeSpacing
        Rectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: Kirigami.Units.gridUnit * 1.6; implicitHeight: implicitWidth
            radius: width / 2
            color: "transparent"
            border.color: Kirigami.Theme.disabledTextColor
            QQC2.Label { anchors.centerIn: parent; text: number; font.weight: Font.DemiBold }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            QQC2.Label { text: heading; font.weight: Font.DemiBold; font.pointSize: Kirigami.Theme.defaultFont.pointSize + 1 }
            QQC2.Label { Layout.fillWidth: true; visible: detail !== ""; text: detail; wrapMode: Text.WordWrap; color: Kirigami.Theme.disabledTextColor }
        }
        QQC2.Button { id: action; visible: text !== ""; Layout.alignment: Qt.AlignTop; onClicked: parent.triggered() }
    }
    component Link: QQC2.Label {
        property string action
        text: "<a href='#'>" + linkText + "</a>"
        property string linkText
        textFormat: Text.StyledText
        onLinkActivated: backend.run(action)
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Kirigami.Units.gridUnit * 1.5
        spacing: Kirigami.Units.gridUnit

        RowLayout {
            spacing: Kirigami.Units.largeSpacing
            Kirigami.Icon { source: "vitrea-logo"; fallback: "file:///usr/share/pixmaps/vitrea-logo.png"; implicitWidth: Kirigami.Units.iconSizes.huge; implicitHeight: implicitWidth }
            ColumnLayout {
                spacing: 2
                Kirigami.Heading { text: "Welcome to Vitrea"; level: 1 }
                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    color: Kirigami.Theme.disabledTextColor
                    text: backend.live ? "You're running Vitrea from the USB stick. Nothing on this computer changes until you install it."
                                       : "Three things to get you started."
                }
            }
        }

        Kirigami.Separator { Layout.fillWidth: true }

        Step {
            number: 1
            heading: "Connect to the internet"
            detail: backend.appleT2 ? "Wi-Fi or a cable. On a Mac, Wi-Fi first needs a one-time setup that copies the Wi-Fi driver files from macOS or the internet."
                                    : "Wi-Fi or a cable. You need it for updates and new apps."
            buttonText: "Wi-Fi Settings"
            buttonIcon: "network-wireless"
            onTriggered: backend.run("wifi")
        }
        QQC2.Button {
            visible: backend.appleT2
            Layout.leftMargin: Kirigami.Units.gridUnit * 2.6
            text: "Set Up Mac Wi-Fi"
            icon.name: "network-wireless-hotspot"
            onClicked: backend.run("macwifi")
        }

        Step {
            number: 2
            heading: backend.live ? "Install Vitrea" : "Get the latest updates"
            detail: backend.live ? "Takes about 10 minutes. You can keep another system, like Windows or Arch, and choose between them when the computer starts."
                                 : "Updates also arrive on their own, in Discover. If one ever causes trouble, an earlier version can be started from the boot menu."
            buttonText: backend.live ? "Install…" : "Updates"
            buttonIcon: backend.live ? "system-installer" : "update-none"
            onTriggered: backend.run(backend.live ? "install" : "updates")
        }

        Step {
            number: 3
            heading: "Explore"
            detail: ""
        }
        ColumnLayout {
            Layout.leftMargin: Kirigami.Units.gridUnit * 2.6
            Layout.topMargin: -Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing
            Link { linkText: "Get apps"; action: "apps" }
            Link { linkText: "Change the wallpaper, colours and more (Vitrea Style)"; action: "style" }
            Link { linkText: "Screen size and night light"; action: "display" }
            Link { linkText: "Try the Hyprland desktop: log out, then choose it at the bottom left of the login screen"; action: "hyprland" }
            Link { linkText: "All settings"; action: "settings" }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            QQC2.CheckBox {
                text: "Show when I log in"
                checked: backend.showAtStartup
                visible: !backend.live
                onToggled: backend.setShowAtStartup(checked)
            }
            Item { Layout.fillWidth: true }
            QQC2.Button { text: "Close"; onClicked: Qt.quit() }
        }
    }
}
