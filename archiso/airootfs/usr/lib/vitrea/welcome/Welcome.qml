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
    readonly property color ink: dark ? "#f2f5ff" : "#14182a"
    readonly property color subInk: dark ? "#b9c2dd" : "#4a5370"
    readonly property color glass: dark ? "#33182040" : "#99ffffff"
    readonly property color glassHover: dark ? "#55304070" : "#ccffffff"
    readonly property color accent: "#2f7cf6"

    // Liquid background (blurred wallpaper look) behind a frosted card
    Rectangle {
        anchors.fill: parent
        radius: 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: win.dark ? "#ff1a2a6b" : "#ffcfe0ff" }
            GradientStop { position: 0.5; color: win.dark ? "#ff301c5e" : "#ffeedcff" }
            GradientStop { position: 1.0; color: win.dark ? "#ff0f4a63" : "#ffc8f3ff" }
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
                    { act: "wifi",     icon: "network-wireless",        title: "Connect to Wi-Fi", desc: "Join a wireless network.", live: false },
                    { act: "display",  icon: "video-display",           title: "Displays",         desc: "Screen size, scaling and night light.", live: false },
                    { act: "updates",  icon: "update-none",             title: "Updates",          desc: "Keep your system safe and up to date.", live: false },
                    { act: "settings", icon: "preferences-system",      title: "All Settings",     desc: "Personalise everything else.", live: false }
                ].filter(function (m) { return backend.live || !m.live })

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 96
                    radius: 18
                    color: area.containsMouse ? win.glassHover : win.glass
                    border.color: modelData.act === "install" ? win.accent : (win.dark ? "#40ffffff" : "#b0ffffff")
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
