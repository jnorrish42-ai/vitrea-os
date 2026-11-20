import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

ApplicationWindow {
    id: win
    width: 820
    height: 700
    minimumWidth: 680
    minimumHeight: 560
    visible: true
    title: "Vitrea Style"
    color: "transparent"

    readonly property color ink: "#eef0ff"
    readonly property color subInk: "#a9aed0"
    property color accent: "#cba6f7"

    // ---------- liquid glass pill button ----------
    component GlassPill: Item {
        id: pill
        property string text
        property string icon: ""
        property bool selected: false
        property color tint: "transparent"
        signal clicked
        implicitWidth: Math.max(96, row.implicitWidth + 36)
        implicitHeight: 42
        scale: area.pressed ? 0.95 : (area.containsMouse ? 1.04 : 1.0)
        Behavior on scale { SpringAnimation { spring: 4.5; damping: 0.28; epsilon: 0.001 } }

        Rectangle {   // accent glow when selected
            anchors.fill: parent
            anchors.margins: -5
            radius: height / 2
            color: "transparent"
            border.width: 6
            border.color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, pill.selected ? 0.22 : 0)
            Behavior on border.color { ColorAnimation { duration: 220 } }
        }
        Rectangle {   // glass body
            id: body
            anchors.fill: parent
            radius: height / 2
            color: pill.tint != Qt.color("transparent") ? pill.tint
                 : pill.selected ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.28)
                 : Qt.rgba(1, 1, 1, area.containsMouse ? 0.16 : 0.09)
            Behavior on color { ColorAnimation { duration: 180 } }
            border.width: 1
            border.color: pill.selected ? Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.95)
                        : Qt.rgba(1, 1, 1, area.containsMouse ? 0.55 : 0.30)
            Behavior on border.color { ColorAnimation { duration: 180 } }
            // top sheen
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
                height: parent.height * 0.48
                radius: height / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.30 : 0.20) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                }
            }
        }
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 8
            Kirigami.Icon { visible: pill.icon !== ""; source: pill.icon; Layout.preferredWidth: 18; Layout.preferredHeight: 18 }
            Label { text: pill.text; color: win.ink; font.pixelSize: 14; font.weight: pill.selected ? Font.DemiBold : Font.Normal }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.clicked()
        }
    }

    // ---------- section card ----------
    component Card: Rectangle {
        default property alias content: inner.data
        property string title
        property string hint
        Layout.fillWidth: true
        implicitHeight: col.implicitHeight + 40
        radius: 22
        color: Qt.rgba(1, 1, 1, 0.06)
        border.color: Qt.rgba(1, 1, 1, 0.14)
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
            height: 36; radius: 21
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.08) }
                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
            }
        }
        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 4
            Label { text: title; color: win.ink; font.pixelSize: 17; font.weight: Font.DemiBold }
            Label { text: hint; color: win.subInk; font.pixelSize: 12; visible: hint !== ""; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            ColumnLayout { id: inner; Layout.fillWidth: true; Layout.topMargin: 10; spacing: 10 }
        }
    }

    // ---------- background ----------
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#ee151526" }
            GradientStop { position: 1; color: "#ee221b38" }
        }
    }
    Repeater {    // soft accent bloom: stacked translucent discs fake a radial glow
        model: 8
        Rectangle {
            required property int index
            width: 640 - index * 70; height: width; radius: width / 2
            x: win.width - 330 - width / 2; y: -170 - width / 2 + 120
            color: Qt.rgba(win.accent.r, win.accent.g, win.accent.b, 0.022)
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        ColumnLayout {
            width: parent.width
            spacing: 16

            RowLayout {
                Layout.margins: 28
                Layout.bottomMargin: 4
                spacing: 16
                Image { source: "file:///usr/share/icons/hicolor/128x128/apps/vitrea-logo.png"; Layout.preferredWidth: 58; Layout.preferredHeight: 58; smooth: true }
                ColumnLayout {
                    spacing: 2
                    Label { text: "Vitrea Style"; color: win.ink; font.pixelSize: 30; font.weight: Font.DemiBold }
                    Label { text: "Make it yours. Every change applies instantly."; color: win.subInk; font.pixelSize: 14 }
                }
            }

            ColumnLayout {
                Layout.leftMargin: 28; Layout.rightMargin: 28; Layout.bottomMargin: 28
                spacing: 16

                Card {
                    title: "Look"
                    hint: "A wallpaper and a matching accent colour."
                    RowLayout {
                        spacing: 12
                        Repeater {
                            model: [{ id: "night", name: "Night", accent: "#cba6f7" },
                                    { id: "dusk", name: "Dusk", accent: "#f5a3b8" },
                                    { id: "neon", name: "Neon", accent: "#22d3ee" }]
                            GlassPill {
                                required property var modelData
                                text: modelData.name
                                selected: lookGroup.current === modelData.id
                                onClicked: { lookGroup.current = modelData.id; win.accent = modelData.accent; backend.setPreset(modelData.id) }
                            }
                        }
                        QtObject { id: lookGroup; property string current: "" }
                    }
                }

                Card {
                    title: "Accent colour"
                    hint: "Highlights, selections and the glow of the glass."
                    RowLayout {
                        spacing: 14
                        Repeater {
                            model: ["#cba6f7", "#89b4fa", "#f5a3b8", "#22d3ee", "#a6e3a1", "#fab387"]
                            Item {
                                required property string modelData
                                width: 40; height: 40
                                scale: sw.containsMouse ? 1.14 : 1
                                Behavior on scale { SpringAnimation { spring: 5; damping: 0.3; epsilon: 0.001 } }
                                Rectangle { anchors.fill: parent; anchors.margins: -5; radius: 25; color: "transparent"; border.width: 2; border.color: win.accent == Qt.color(modelData) ? "#ffffff" : "transparent" }
                                Rectangle { anchors.fill: parent; radius: 20; color: modelData; border.color: Qt.rgba(1, 1, 1, 0.5) }
                                Rectangle { x: 6; y: 4; width: 28; height: 14; radius: 7; color: Qt.rgba(1, 1, 1, 0.35) }
                                MouseArea { id: sw; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { win.accent = modelData; backend.setAccent(modelData) } }
                            }
                        }
                    }
                }

                Card {
                    title: "Liquid Glass"
                    hint: "How see-through the bar, dock and menus are, and how much they bend the light behind them."
                    RowLayout {
                        spacing: 12
                        Repeater {
                            model: [{ id: "clear", name: "Clear" }, { id: "liquid", name: "Liquid" }, { id: "frosted", name: "Frosted" }]
                            GlassPill {
                                required property var modelData
                                text: modelData.name
                                selected: glassGroup.current === modelData.id
                                onClicked: { glassGroup.current = modelData.id; backend.setGlass(modelData.id) }
                            }
                        }
                        QtObject { id: glassGroup; property string current: backend.glass }
                    }
                    RowLayout {
                        spacing: 14
                        Label { text: "Refraction"; color: win.ink; font.pixelSize: 14 }
                        Slider {
                            id: refr
                            Layout.fillWidth: true
                            from: 0; to: 20; stepSize: 1
                            value: backend.refraction
                            onPressedChanged: if (!pressed) backend.setRefraction(value)
                        }
                        Label { text: Math.round(refr.value); color: win.subInk; font.pixelSize: 13; Layout.preferredWidth: 22 }
                    }
                    RowLayout {
                        spacing: 12
                        Label { text: "Glass effect"; color: win.ink; font.pixelSize: 14; Layout.preferredWidth: 110 }
                        Repeater {
                            model: [{ id: "auto", name: "Automatic" }, { id: "on", name: "Always on" }, { id: "off", name: "Off" }]
                            GlassPill {
                                required property var modelData
                                text: modelData.name
                                selected: modeGroup.current === modelData.id
                                onClicked: { modeGroup.current = modelData.id; backend.setGlassMode(modelData.id) }
                            }
                        }
                        QtObject { id: modeGroup; property string current: backend.glassMode }
                    }
                    Label { text: "Automatic turns the glass off on computers without graphics acceleration (like most virtual machines), so the desktop stays smooth."
                        color: win.subInk; font.pixelSize: 12; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                }

                Card {
                    title: "Motion"
                    hint: "Animation speed and how windows move."
                    RowLayout {
                        spacing: 12
                        Repeater {
                            model: [{ id: "snappy", name: "Snappy" }, { id: "fluid", name: "Fluid" }, { id: "relaxed", name: "Relaxed" }]
                            GlassPill {
                                required property var modelData
                                text: modelData.name
                                selected: speedGroup.current === modelData.id
                                onClicked: { speedGroup.current = modelData.id; backend.setSpeed(modelData.id) }
                            }
                        }
                        QtObject { id: speedGroup; property string current: backend.speed }
                    }
                    RowLayout {
                        spacing: 12
                        Label { text: "Minimise"; color: win.ink; font.pixelSize: 14; Layout.preferredWidth: 110 }
                        GlassPill { text: "Squash"; selected: !lampGroup.on; onClicked: { lampGroup.on = false; backend.setMagicLamp(false) } }
                        GlassPill { text: "Magic lamp"; selected: lampGroup.on; onClicked: { lampGroup.on = true; backend.setMagicLamp(true) } }
                        QtObject { id: lampGroup; property bool on: backend.magicLamp }
                    }
                    RowLayout {
                        spacing: 12
                        Label { text: "Jelly windows"; color: win.ink; font.pixelSize: 14; Layout.preferredWidth: 110 }
                        GlassPill { text: jellyGroup.on ? "On" : "Off"; selected: jellyGroup.on
                            onClicked: { jellyGroup.on = !jellyGroup.on; backend.setJelly(jellyGroup.on) } }
                        QtObject { id: jellyGroup; property bool on: backend.jelly }
                    }
                }

                Card {
                    title: "Layout"
                    hint: "Where the dock sits and what lives on your desktop."
                    RowLayout {
                        spacing: 12
                        Label { text: "Dock"; color: win.ink; font.pixelSize: 14; Layout.preferredWidth: 110 }
                        Repeater {
                            model: [{ id: "bottom", name: "Bottom" }, { id: "left", name: "Left" }, { id: "right", name: "Right" }]
                            GlassPill {
                                required property var modelData
                                text: modelData.name
                                selected: dockGroup.current === modelData.id
                                onClicked: { dockGroup.current = modelData.id; backend.setDock(modelData.id) }
                            }
                        }
                        QtObject { id: dockGroup; property string current: "bottom" }
                    }
                    RowLayout {
                        spacing: 12
                        Label { text: "Widgets"; color: win.ink; font.pixelSize: 14; Layout.preferredWidth: 110 }
                        GlassPill { icon: "preferences-system-time"; text: "Big clock"; selected: w.clock
                            onClicked: { w.clock = !w.clock; backend.setWidget("org.vitrea.clock", w.clock) } }
                        GlassPill { icon: "media-playback-start"; text: "Music"; selected: w.music
                            onClicked: { w.music = !w.music; backend.setWidget("org.vitrea.music", w.music) } }
                        QtObject { id: w; property bool clock: true; property bool music: true }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    GlassPill { icon: "preferences-system"; text: "More in System Settings"; onClicked: backend.openSettings() }
                }
            }
        }
    }
}
