// Vitrea Style: a plain settings window in the system's own style.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

QQC2.ApplicationWindow {
    id: win
    width: 720
    height: 760
    minimumWidth: 560
    minimumHeight: 480
    visible: true
    title: "Vitrea Style"

    readonly property var shown: backend.widgets.split(",")

    // a ComboBox over [{text, value}] that starts on `current` and reports the chosen value
    component Choice: QQC2.ComboBox {
        property string current
        signal chosen(string value)
        textRole: "text"
        valueRole: "value"
        Component.onCompleted: currentIndex = Math.max(0, indexOfValue(current))
        onActivated: chosen(currentValue)
    }
    component Hint: QQC2.Label {
        Layout.fillWidth: true
        Layout.maximumWidth: Kirigami.Units.gridUnit * 24
        wrapMode: Text.WordWrap
        font: Kirigami.Theme.smallFont
        color: Kirigami.Theme.disabledTextColor
    }

    QQC2.ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth

        Kirigami.FormLayout {
            width: parent.width
            wideMode: width > Kirigami.Units.gridUnit * 30

            // ---------------- Wallpaper ----------------
            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Wallpaper" }
            RowLayout {
                Kirigami.FormData.label: "Photo:"
                spacing: Kirigami.Units.largeSpacing
                property string current: backend.wallpaper
                id: walls
                Repeater {
                    model: [
                        { id: "lake", name: "Lake", dir: "summer_1am" },
                        { id: "mist", name: "Mist", dir: "DarkestHour" },
                        { id: "forest", name: "Forest", dir: "Path" },
                        { id: "ember", name: "Ember", dir: "FallenLeaf" }
                    ]
                    ColumnLayout {
                        required property var modelData
                        spacing: Kirigami.Units.smallSpacing
                        Rectangle {
                            implicitWidth: 120; implicitHeight: 75
                            radius: Kirigami.Units.cornerRadius + 2
                            color: "transparent"
                            border.width: walls.current === modelData.id ? 3 : 0
                            border.color: Kirigami.Theme.highlightColor
                            Image {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: "file:///usr/share/wallpapers/" + modelData.dir + "/contents/screenshot.jpg"
                                sourceSize: Qt.size(240, 150)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { walls.current = modelData.id; backend.setWallpaper(modelData.id) }
                            }
                        }
                        QQC2.Label { Layout.alignment: Qt.AlignHCenter; text: modelData.name }
                    }
                }
            }
            Hint { text: "Photos from KDE's wallpaper collection. The lock screen uses the same one." }

            // ---------------- Colours ----------------
            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Colours" }
            RowLayout {
                Kirigami.FormData.label: "Mode:"
                QQC2.RadioButton { text: "Dark"; checked: backend.dark; onToggled: if (checked) backend.setDark(true) }
                QQC2.RadioButton { text: "Light"; checked: !backend.dark; onToggled: if (checked) backend.setDark(false) }
            }
            QQC2.RadioButton {
                id: accentAuto
                Kirigami.FormData.label: "Accent colour:"
                text: "Match the wallpaper"
                checked: backend.accentAuto
                onToggled: if (checked) backend.setAccentAuto()
            }
            RowLayout {
                spacing: Kirigami.Units.smallSpacing
                QQC2.RadioButton { id: accentPick; text: "Choose:"; checked: !backend.accentAuto }
                Repeater {
                    model: ["#3daee9", "#7f6fc4", "#c25b78", "#3a9a6c", "#c8862f", "#6d7b8a"]
                    Rectangle {
                        required property string modelData
                        width: Kirigami.Units.gridUnit * 1.3; height: width; radius: width / 2
                        color: modelData
                        border.width: swatch.containsMouse ? 2 : 0
                        border.color: Kirigami.Theme.textColor
                        MouseArea {
                            id: swatch
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { accentPick.checked = true; backend.setAccent(parent.modelData) }
                        }
                    }
                }
            }

            // ---------------- Top bar and dock ----------------
            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Top bar and dock" }
            Choice {
                Kirigami.FormData.label: "Transparency:"
                model: [{ text: "More see-through", value: "more" }, { text: "Normal", value: "normal" },
                        { text: "Less see-through", value: "less" }]
                current: backend.transparency
                onChosen: value => backend.setTransparency(value)
            }
            Choice {
                Kirigami.FormData.label: "Glass effect:"
                model: [{ text: "Automatic", value: "auto" }, { text: "Always on", value: "on" }, { text: "Off", value: "off" }]
                current: backend.glassMode
                onChosen: value => backend.setGlassMode(value)
            }
            Hint { text: "Automatic turns the glass effect off on computers without graphics acceleration (like most virtual machines). Menus and pop-ups are always solid." }

            // ---------------- Motion ----------------
            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Motion" }
            Choice {
                Kirigami.FormData.label: "Animation speed:"
                model: [{ text: "Fast", value: "fast" }, { text: "Normal", value: "normal" }, { text: "Slow", value: "slow" }]
                current: backend.speed
                onChosen: value => backend.setSpeed(value)
            }
            Choice {
                Kirigami.FormData.label: "Minimise effect:"
                model: [{ text: "Squash", value: "squash" }, { text: "Magic lamp", value: "lamp" }]
                current: backend.magicLamp ? "lamp" : "squash"
                onChosen: value => backend.setMagicLamp(value === "lamp")
            }
            QQC2.CheckBox {
                text: "Wobbly windows when moved"
                checked: backend.wobbly
                onToggled: backend.setWobbly(checked)
            }

            // ---------------- Desktop ----------------
            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Desktop" }
            Choice {
                Kirigami.FormData.label: "Dock position:"
                model: [{ text: "Bottom", value: "bottom" }, { text: "Left", value: "left" }, { text: "Right", value: "right" }]
                current: "bottom"
                onChosen: value => backend.setDock(value)
            }
            QQC2.CheckBox {
                Kirigami.FormData.label: "On the desktop:"
                text: "Large clock"
                checked: win.shown.indexOf("org.vitrea.clock") >= 0
                onToggled: backend.setWidget("org.vitrea.clock", checked)
            }
            QQC2.CheckBox {
                text: "Now Playing card (shows while music plays)"
                checked: win.shown.indexOf("org.vitrea.music") >= 0
                onToggled: backend.setWidget("org.vitrea.music", checked)
            }
            QQC2.CheckBox {
                text: "Yumeka"
                checked: win.shown.indexOf("org.vitrea.yumeka") >= 0
                onToggled: backend.setWidget("org.vitrea.yumeka", checked)
            }

            // ---------------- Keyboard ----------------
            Kirigami.Separator { Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Keyboard" }
            QQC2.Switch {
                Kirigami.FormData.label: "Mac-style keys:"
                checked: backend.macKeys
                onToggled: backend.setMacKeys(checked)
            }
            Hint {
                text: "Cmd works like Ctrl: Cmd+C, Cmd+V, Cmd+Z, Cmd+Q and so on. Cmd+Space searches and Cmd+Shift+3 / 4 / 5 take a screenshot, snip an area or record (after you next log in). The Control key then works like the Windows/Super key. In the terminal, copy and paste are Cmd+Shift+C and Cmd+Shift+V."
            }

            // ---------------- Mac hardware (T2 edition on a Mac) ----------------
            Kirigami.Separator {
                visible: backend.macHelper && backend.appleHardware
                Kirigami.FormData.isSection: true; Kirigami.FormData.label: "Mac"
            }
            Choice {
                visible: backend.macHelper && backend.hasTouchBar
                Kirigami.FormData.label: "Touch Bar shows:"
                model: [{ text: "Brightness, volume and media", value: "media" }, { text: "F1 to F12", value: "fkeys" }]
                current: backend.touchBar
                onChosen: value => backend.setTouchBar(value)
            }
            Hint {
                visible: backend.macHelper && backend.hasTouchBar
                text: "Hold Fn to see the other set."
            }
            Choice {
                visible: backend.macHelper && backend.appleHardware
                Kirigami.FormData.label: "Fans:"
                model: [{ text: "Quiet", value: "quiet" }, { text: "Balanced", value: "balanced" },
                        { text: "Cool (spin up early)", value: "cool" }, { text: "Full speed", value: "max" }]
                current: backend.fanProfile
                onChosen: value => backend.setFans(value)
            }
            QQC2.Label {
                id: sensors
                visible: backend.macHelper && backend.appleHardware && text !== ""
                Kirigami.FormData.label: "Now:"
                text: backend.sensors()
                Timer {
                    interval: 2000; repeat: true
                    running: sensors.visible && win.active
                    onTriggered: sensors.text = backend.sensors()
                }
            }

            // ---------------- more ----------------
            Item { Kirigami.FormData.isSection: true }
            QQC2.Button {
                icon.name: "preferences-system"
                text: "All Settings…"
                onClicked: backend.openSettings("")
            }
        }
    }
}
