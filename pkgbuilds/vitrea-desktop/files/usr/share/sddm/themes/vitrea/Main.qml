// Vitrea OS login screen: liquid-glass card over the Glass Blossom wallpaper.
// SDDM greeter theme (Qt 6). Context objects provided by SDDM: sddm, userModel, sessionModel, config, keyboard.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

Item {
    id: root
    width: 1920
    height: 1080

    readonly property color ink: "#cdd6f4"
    readonly property real s: Math.max(0.75, Math.min(width / 1920, height / 1080) * 1.25)   // UI scale
    property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    property var users: []
    property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
    readonly property var currentUser: users.length > userIndex ? users[userIndex] : ({ name: userModel.lastUser, real: userModel.lastUser, icon: "" })

    function doLogin() {
        message.text = ""
        busy.visible = true
        sddm.login(currentUser.name, password.text, sessionIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            busy.visible = false
            password.text = ""
            message.text = "That password didn't work. Try again."
            shake.start()
            password.forceActiveFocus()
        }
        function onInformationMessage(msg) { message.text = msg }
    }

    // collect users (name, real name, avatar)
    Repeater {
        model: userModel
        delegate: Item {
            Component.onCompleted: {
                var u = root.users.slice()
                u[index] = { name: model.name, real: model.realName || model.name, icon: model.icon }
                root.users = u
            }
        }
    }

    // ---------- background ----------
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background || "file:///usr/share/wallpapers/VitreaDusk/contents/images/3840x2160.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        smooth: true
    }
    // gentle darkening at the top so the clock reads well
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#5911111b" }
            GradientStop { position: 0.45; color: "#0011111b" }
            GradientStop { position: 1.0; color: "#6611111b" }
        }
    }

    // ---------- clock ----------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.09
        spacing: 2 * root.s
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: clock.implicitWidth; height: clock.implicitHeight
            Text {   // soft shadow that works without GPU effects
                x: 0; y: 3
                text: clock.text; font: clock.font; color: "#000000"; opacity: 0.18
            }
            Text {
                id: clock
                color: root.ink
                font.family: "JetBrainsMono Nerd Font"; font.weight: Font.Bold; font.pixelSize: 104 * root.s
                text: Qt.formatTime(new Date(), "h:mm")
            }
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.ink; opacity: 0.92
            font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: 26 * root.s
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: { clock.text = Qt.formatTime(new Date(), "h:mm"); date.text = Qt.formatDate(new Date(), "dddd, d MMMM") }
    }

    // ---------- glass card ----------
    Item {
        id: card
        width: 400 * root.s
        height: col.implicitHeight + 56 * root.s
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.40

        // blurred wallpaper behind the card (liquid glass: light blur + colour boost)
        ShaderEffectSource {
            id: behind
            sourceItem: wallpaper
            sourceRect: Qt.rect(card.x, card.y, card.width, card.height)
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: behind
            blurEnabled: true; blur: 0.45; blurMax: 32
            saturation: 0.35; brightness: 0.06
            maskEnabled: true
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle { width: card.width; height: card.height; radius: 18 * root.s; color: "black" }
                hideSource: true
            }
        }
        Rectangle {            // tint + gloss + specular rim
            anchors.fill: parent
            radius: 18 * root.s
            color: "#d9181825"
            border.width: 1
            border.color: "#45475a"
        }
        Rectangle {            // inner top highlight
            x: 22 * root.s; y: 1; width: parent.width - 44 * root.s; height: 1
            color: "#cba6f7"; opacity: 0.55; radius: 1
        }

        SequentialAnimation {
            id: shake
            loops: 1
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 12; duration: 70 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -8; duration: 60 }
            NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
        }

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 * root.s }
            spacing: 14 * root.s

            // avatar
            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 96 * root.s; height: width
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    gradient: Gradient {
                        GradientStop { position: 0; color: "#cba6f7" }
                        GradientStop { position: 1; color: "#89b4fa" }
                    }
                    border.width: 2; border.color: "#45475a"
                    Text {
                        anchors.centerIn: parent
                        text: (root.currentUser.real || "?").charAt(0).toUpperCase()
                        color: "#11111b"; font.family: "Inter"; font.weight: Font.Bold; font.pixelSize: 44 * root.s
                        visible: avatarImg.status !== Image.Ready
                    }
                }
                Image {
                    id: avatarImg
                    anchors.fill: parent; anchors.margins: 2
                    source: root.currentUser.icon ? root.currentUser.icon : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }
                MultiEffect {
                    anchors.fill: avatarImg; source: avatarImg
                    visible: avatarImg.status === Image.Ready
                    maskEnabled: true
                    maskSource: ShaderEffectSource { sourceItem: Rectangle { width: avatarImg.width; height: avatarImg.height; radius: width / 2 } hideSource: true }
                }
            }

            // name (click to switch user when there are several)
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.currentUser.real
                color: root.ink; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 24 * root.s
                MouseArea {
                    anchors.fill: parent; enabled: root.users.length > 1; cursorShape: Qt.PointingHandCursor
                    onClicked: root.userIndex = (root.userIndex + 1) % root.users.length
                }
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root.users.length > 1
                text: "Click your name to switch user"
                color: root.ink; opacity: 0.7; font.family: "Inter"; font.pixelSize: 12 * root.s
            }

            // password pill
            Rectangle {
                Layout.fillWidth: true
                height: 46 * root.s; radius: 12 * root.s
                color: password.activeFocus ? "#45475a" : "#313244"
                border.width: 1; border.color: password.activeFocus ? "#cba6f7" : "#585b70"
                TextField {
                    id: password
                    anchors { left: parent.left; right: go.left; verticalCenter: parent.verticalCenter; leftMargin: 18 * root.s }
                    echoMode: TextInput.Password
                    placeholderText: "Password"
                    placeholderTextColor: "#7f849c"
                    color: "#cdd6f4"
                    font.family: "Inter"; font.pixelSize: 16 * root.s
                    background: Item {}
                    focus: true
                    Keys.onReturnPressed: root.doLogin()
                    Keys.onEnterPressed: root.doLogin()
                    Component.onCompleted: forceActiveFocus()
                }
                Rectangle {
                    id: go
                    width: 36 * root.s; height: width; radius: 9 * root.s
                    anchors { right: parent.right; rightMargin: 5 * root.s; verticalCenter: parent.verticalCenter }
                    color: goArea.pressed ? "#b4befe" : "#cba6f7"
                    border.width: 0
                    Text { anchors.centerIn: parent; text: "→"; color: "#11111b"; font.pixelSize: 20 * root.s; font.weight: Font.Bold }
                    MouseArea { id: goArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
                }
            }
            BusyIndicator { id: busy; visible: false; running: visible; Layout.alignment: Qt.AlignHCenter; implicitHeight: 28 * root.s; implicitWidth: implicitHeight }
            Text {
                id: message
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                visible: text.length > 0
                color: "#f38ba8"; font.family: "Inter"; font.pixelSize: 13 * root.s
            }

            // desktop chooser: big, friendly chips instead of a tiny dropdown
            Text {
                Layout.topMargin: 4 * root.s
                Layout.alignment: Qt.AlignHCenter
                text: "Desktop"
                color: root.ink; opacity: 0.8; font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: 12 * root.s
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * root.s
                Repeater {
                    model: sessionModel
                    delegate: Rectangle {
                        required property int index
                        required property string name
                        readonly property bool hypr: name.toLowerCase().indexOf("hyprland") >= 0
                        readonly property bool selected: root.sessionIndex === index
                        Layout.fillWidth: true
                        height: 58 * root.s; radius: 12 * root.s
                        color: selected ? "#45475a" : (chip.containsMouse ? "#3b3d52" : "#313244")
                        border.width: selected ? 2 : 1
                        border.color: selected ? "#cba6f7" : "#45475a"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        Column {
                            anchors.centerIn: parent
                            spacing: 1
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: hypr ? "Hyprland (43PR)" : (name.toLowerCase().indexOf("plasma") >= 0 ? "Plasma" : name)
                                color: "#cdd6f4"; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 14 * root.s
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: hypr ? "Tiling · keyboard" : "Easy · point and click"
                                color: "#a6adc8"; font.family: "Inter"; font.pixelSize: 11 * root.s
                            }
                        }
                        MouseArea { id: chip; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.sessionIndex = index }
                    }
                }
            }
        }
    }

    // ---------- power buttons ----------
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 28 * root.s }
        spacing: 14 * root.s
        Repeater {
            model: [
                { label: "Sleep", glyph: "☾", act: function () { sddm.suspend() }, show: sddm.canSuspend },
                { label: "Restart", glyph: "↻", act: function () { sddm.reboot() }, show: sddm.canReboot },
                { label: "Shut Down", glyph: "⏻", act: function () { sddm.powerOff() }, show: sddm.canPowerOff }
            ]
            delegate: Column {
                required property var modelData
                visible: modelData.show
                spacing: 6 * root.s
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 50 * root.s; height: width; radius: width / 2
                    color: pa.containsMouse ? "#45475a" : "#d9181825"
                    border.width: 1; border.color: "#45475a"
                    Text { anchors.centerIn: parent; text: modelData.glyph; color: "#cdd6f4"; font.pixelSize: 22 * root.s }
                    MouseArea { id: pa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.act() }
                }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: "#a6adc8"; font.family: "Inter"; font.pixelSize: 12 * root.s }
            }
        }
    }

    // ---------- branding ----------
    Row {
        anchors { left: parent.left; bottom: parent.bottom; margins: 28 * root.s }
        spacing: 10 * root.s
        Image { source: "file:///usr/share/icons/hicolor/128x128/apps/vitrea-logo.png"; width: 32 * root.s; height: width; smooth: true }
        Text { anchors.verticalCenter: parent.verticalCenter; text: "Vitrea OS"; color: "#cdd6f4"; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 16 * root.s }
    }
}
