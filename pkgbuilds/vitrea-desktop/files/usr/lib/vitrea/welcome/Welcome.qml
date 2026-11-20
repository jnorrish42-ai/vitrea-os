import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

ApplicationWindow {
    id: win
    width: 760
    height: 560
    minimumWidth: 640
    minimumHeight: 500
    visible: true
    title: "Welcome to Vitrea OS"

    readonly property bool dark: backend.darkMode
    readonly property color ink: dark ? "#cdd6f4" : "#14182a"
    readonly property color subInk: dark ? "#a6adc8" : "#4a5370"
    readonly property color glass: dark ? "#313244" : "#99ffffff"
    readonly property color glassHover: dark ? "#45475a" : "#ccffffff"
    readonly property color accent: dark ? "#cba6f7" : "#2f7cf6"

    // Liquid background (blurred wallpaper look) behind a frosted card
    Rectangle {
        anchors.fill: parent
        radius: 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: win.dark ? "#ff181825" : "#ffcfe0ff" }
            GradientStop { position: 0.5; color: win.dark ? "#ff1e1e2e" : "#ffeedcff" }
            GradientStop { position: 1.0; color: win.dark ? "#ff181825" : "#ffc8f3ff" }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        spacing: 18

        RowLayout {
            spacing: 18
            Kirigami.Icon {
                source: "vitrea-logo"
                fallback: "file:///usr/share/pixmaps/vitrea-logo.png"
                Layout.preferredWidth: 72; Layout.preferredHeight: 72
            }
            ColumnLayout {
                spacing: 2
                Label { text: "Welcome to Vitrea OS"; font.pixelSize: 30; font.weight: Font.DemiBold; color: win.ink }
                Label {
                    text: backend.live ? "You're trying Vitrea from a USB stick. Nothing is changed on your computer until you install."
                                       : "Everything you need to get started, in one place."
                    color: win.subInk; font.pixelSize: 14; wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        GridLayout {
            columns: 3
            rowSpacing: 14
            columnSpacing: 14
            Layout.fillWidth: true
            Layout.fillHeight: true

            Repeater {
                model: [
                    { act: "install",  icon: "system-software-install", title: "Install Vitrea",   desc: "Put Vitrea on this computer. Takes about 10 minutes.", live: true },
                    { act: "apps",     icon: "plasmadiscover",          title: "Get Apps",         desc: "Browse thousands of free apps in Discover.", live: false },
                    { act: "hyprland", icon: "preferences-system-windows", title: "Try Hyprland",   desc: "Log out, then pick Hyprland (43PR) on the login screen.", live: false },
                    { act: "macwifi",  icon: "network-wireless-hotspot", title: "Mac Wi-Fi Setup", desc: "Copy your Mac's Wi-Fi and Bluetooth firmware from macOS.", live: false, t2: true },
                    { act: "wifi",     icon: "network-wireless",        title: "Connect to Wi-Fi", desc: "Join a wireless network.", live: false },
                    { act: "display",  icon: "video-display",           title: "Displays",         desc: "Screen size, scaling and night light.", live: false },
                    { act: "updates",  icon: "update-none",             title: "Updates",          desc: "Keep your system safe and up to date.", live: false },
                    { act: "settings", icon: "preferences-system",      title: "All Settings",     desc: "Personalise everything else.", live: false }
                ].filter(function (m) { return (backend.live || !m.live) && (backend.appleT2 || !m.t2) })

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 96
                    radius: 18
                    color: area.containsMouse ? win.glassHover : win.glass
                    border.color: modelData.act === "install" ? win.accent : (win.dark ? "#45475a" : "#b0ffffff")
                    border.width: modelData.act === "install" ? 2 : 1
                    Behavior on color { ColorAnimation { duration: 120 } }
                    scale: area.pressed ? 0.97 : 1.0
                    Behavior on scale { NumberAnimation { duration: 90 } }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 4
                        Kirigami.Icon {
                            source: modelData.icon
                            Layout.preferredWidth: 32; Layout.preferredHeight: 32
                        }
                        Label { text: modelData.title; color: win.ink; font.pixelSize: 15; font.weight: Font.DemiBold }
                        Label { text: modelData.desc; color: win.subInk; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.run(modelData.act)
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Label { text: "Appearance:"; color: win.ink; font.pixelSize: 13 }
            Button { text: "☀  Light"; onClicked: backend.run("light") }
            Button { text: "☾  Dark"; onClicked: backend.run("dark") }
            Item { Layout.fillWidth: true }
            CheckBox {
                text: "Show at startup"
                checked: backend.showAtStartup
                visible: !backend.live
                onToggled: backend.setShowAtStartup(checked)
            }
            Button { text: "Let's go"; highlighted: true; onClicked: Qt.quit() }
        }
    }
}
