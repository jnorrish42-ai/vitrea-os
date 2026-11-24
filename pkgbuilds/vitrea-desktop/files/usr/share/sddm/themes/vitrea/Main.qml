// Vitrea OS login screen: matches the lock screen (blurred photo, clock, one password field).
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
        sessionMenu.visible = false
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

    // ---------- background: the photo, softly blurred like the lock screen's prompt ----------
    Image {
        id: wallpaper
        anchors.fill: parent
        source: config.background || "file:///usr/share/wallpapers/summer_1am/contents/images/2560x1600.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        smooth: true
        visible: GraphicsInfo.api === GraphicsInfo.Software   // the blurred copy below replaces it on a GPU
    }
    MultiEffect {
        anchors.fill: parent
        source: wallpaper
        visible: GraphicsInfo.api !== GraphicsInfo.Software
        blurEnabled: true; blur: 1.0; blurMax: 48
    }
    Rectangle { anchors.fill: parent; color: "black"; opacity: 0.28 }

    // ---------- date and time ----------
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.10
        spacing: -6 * root.s
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: Qt.rgba(1, 1, 1, 0.92)
            font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 21 * root.s
            text: Qt.formatDate(new Date(), "dddd d MMMM")
        }
        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: "white"
            font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: 112 * root.s
            font.letterSpacing: -4 * root.s
            font.features: { "tnum": 1 }
            text: Qt.formatTime(new Date(), "h:mm")
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: { clock.text = Qt.formatTime(new Date(), "h:mm"); date.text = Qt.formatDate(new Date(), "dddd d MMMM") }
    }

    // ---------- user and password ----------
    ColumnLayout {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.56 - height / 2
        width: 300 * root.s
        spacing: 0
        transform: Translate { id: shakeX }

        SequentialAnimation {
            id: shake
            NumberAnimation { target: shakeX; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: shakeX; property: "x"; to: 10; duration: 70 }
            NumberAnimation { target: shakeX; property: "x"; to: -6; duration: 60 }
            NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 60 }
        }

        // avatar: the user's picture, or their initial on frosted white
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 88 * root.s; Layout.preferredHeight: 88 * root.s
            Rectangle {
                anchors.fill: parent; radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.16)
                border.color: Qt.rgba(1, 1, 1, 0.30)
            }
            Text {
                anchors.centerIn: parent
                text: (root.currentUser.real || "?").charAt(0).toUpperCase()
                color: "white"; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 38 * root.s
                visible: avatarImg.status !== Image.Ready
            }
            Image {
                id: avatarImg
                anchors.fill: parent
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
            Layout.topMargin: 14 * root.s
            text: root.currentUser.real
            color: "white"; font.family: "Inter"; font.weight: Font.DemiBold; font.pixelSize: 20 * root.s
            MouseArea {
                anchors.fill: parent; enabled: root.users.length > 1; cursorShape: Qt.PointingHandCursor
                onClicked: root.userIndex = (root.userIndex + 1) % root.users.length
            }
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2 * root.s
            visible: root.users.length > 1
            text: "Click your name to switch user"
            color: Qt.rgba(1, 1, 1, 0.65); font.family: "Inter"; font.pixelSize: 12 * root.s
        }

        // password field with the arrow inside it
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 18 * root.s
            Layout.preferredWidth: 270 * root.s; Layout.preferredHeight: 42 * root.s
            TextField {
                id: password
                anchors.fill: parent
                echoMode: TextInput.Password
                passwordCharacter: "●"
                placeholderText: "Enter Password"
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.62)
                color: "white"
                selectionColor: Qt.rgba(1, 1, 1, 0.35)
                leftPadding: 18 * root.s; rightPadding: 46 * root.s
                verticalAlignment: TextInput.AlignVCenter
                font.family: "Inter"
                font.pixelSize: (text.length > 0 ? 11 : 15) * root.s
                font.letterSpacing: text.length > 0 ? 2 : 0
                background: Rectangle {
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, password.activeFocus ? 0.20 : 0.14)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, password.activeFocus ? 0.42 : 0.24)
                }
                focus: true
                Keys.onReturnPressed: root.doLogin()
                Keys.onEnterPressed: root.doLogin()
                Component.onCompleted: forceActiveFocus()
            }
            Rectangle {
                id: go
                anchors { right: parent.right; rightMargin: 7 * root.s; verticalCenter: parent.verticalCenter }
                width: 28 * root.s; height: width; radius: width / 2
                color: goArea.pressed ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.92)
                opacity: password.text.length > 0 ? 1 : 0
                scale: password.text.length > 0 ? 1 : 0.6
                Behavior on opacity { NumberAnimation { duration: 160 } }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                Canvas {
                    anchors.centerIn: parent
                    width: 14 * root.s; height: width
                    onPaint: {
                        var c = getContext("2d"), k = width / 14
                        c.reset(); c.scale(k, k)
                        c.strokeStyle = "#1c1b22"; c.lineWidth = 2; c.lineCap = "round"; c.lineJoin = "round"
                        c.beginPath(); c.moveTo(2, 7); c.lineTo(12, 7); c.moveTo(7.5, 2.5); c.lineTo(12, 7); c.lineTo(7.5, 11.5); c.stroke()
                    }
                }
                MouseArea { id: goArea; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.doLogin() }
            }
        }

        BusyIndicator { id: busy; visible: false; running: visible; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 10 * root.s; implicitHeight: 24 * root.s; implicitWidth: implicitHeight }
        Text {
            id: message
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 12 * root.s
            Layout.preferredWidth: 340 * root.s
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: Qt.rgba(1, 1, 1, 0.78); font.family: "Inter"; font.pixelSize: 13 * root.s
        }
    }

    // ---------- bottom row: desktop on the left, power on the right ----------
    component BarButton: Item {
        id: bb
        property string label
        property bool chevron: false
        signal clicked
        implicitWidth: lbl.implicitWidth + (chevron ? 18 : 0) * root.s + 28 * root.s
        implicitHeight: 34 * root.s
        Rectangle {
            anchors.fill: parent; radius: height / 2
            color: Qt.rgba(1, 1, 1, ma.pressed ? 0.22 : (ma.containsMouse ? 0.14 : 0))
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Text {
            id: lbl
            x: 14 * root.s; anchors.verticalCenter: parent.verticalCenter
            text: bb.label
            color: Qt.rgba(1, 1, 1, 0.82); font.family: "Inter"; font.weight: Font.Medium; font.pixelSize: 13 * root.s
        }
        Canvas {   // small down chevron
            visible: bb.chevron
            anchors.left: lbl.right; anchors.leftMargin: 7 * root.s; anchors.verticalCenter: parent.verticalCenter
            width: 10 * root.s; height: 6 * root.s
            onPaint: {
                var c = getContext("2d"); c.reset()
                c.strokeStyle = Qt.rgba(1, 1, 1, 0.82); c.lineWidth = 1.6; c.lineCap = "round"; c.lineJoin = "round"
                c.beginPath(); c.moveTo(1, 1); c.lineTo(width / 2, height - 1); c.lineTo(width - 1, 1); c.stroke()
            }
        }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: bb.clicked() }
    }

    // session names, nicer than the .desktop file names
    function sessionLabel(n) {
        var l = (n || "").toLowerCase()
        if (l.indexOf("hyprland") >= 0) return "Hyprland (43PR)"
        if (l.indexOf("plasma") >= 0) return "Plasma"
        return n
    }
    property var sessionNames: []
    Repeater {
        model: sessionModel
        delegate: Item {
            required property int index
            required property string name
            Component.onCompleted: { var a = root.sessionNames.slice(); a[index] = name; root.sessionNames = a }
        }
    }

    Row {
        anchors { left: parent.left; bottom: parent.bottom; margins: 22 * root.s }
        spacing: 4 * root.s
        BarButton {
            label: root.sessionLabel(root.sessionNames[root.sessionIndex])
            chevron: root.sessionNames.length > 1
            onClicked: sessionMenu.visible = !sessionMenu.visible
        }
    }
    // the desktop list, opening upwards from the bottom-left
    Rectangle {
        id: sessionMenu
        visible: false
        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 22 * root.s; bottomMargin: 62 * root.s }
        width: 220 * root.s; height: menuCol.implicitHeight + 12 * root.s
        radius: 14 * root.s
        color: Qt.rgba(0.08, 0.08, 0.1, 0.72)
        border.color: Qt.rgba(1, 1, 1, 0.14)
        Column {
            id: menuCol
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 * root.s }
            Repeater {
                model: root.sessionNames
                delegate: Rectangle {
                    required property int index
                    required property string modelData
                    width: menuCol.width; height: 36 * root.s; radius: 9 * root.s
                    color: Qt.rgba(1, 1, 1, mi.containsMouse ? 0.12 : 0)
                    Text {
                        x: 12 * root.s; anchors.verticalCenter: parent.verticalCenter
                        text: root.sessionLabel(modelData)
                        color: "white"; font.family: "Inter"; font.pixelSize: 14 * root.s
                        font.weight: root.sessionIndex === index ? Font.DemiBold : Font.Normal
                    }
                    Text {
                        anchors.right: parent.right; anchors.rightMargin: 12 * root.s; anchors.verticalCenter: parent.verticalCenter
                        visible: root.sessionIndex === index
                        text: "✓"; color: "white"; font.pixelSize: 13 * root.s
                    }
                    MouseArea { id: mi; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { root.sessionIndex = index; sessionMenu.visible = false; password.forceActiveFocus() } }
                }
            }
        }
    }

    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 22 * root.s }
        spacing: 4 * root.s
        BarButton { visible: sddm.canSuspend; label: "Sleep"; onClicked: sddm.suspend() }
        BarButton { visible: sddm.canReboot; label: "Restart"; onClicked: sddm.reboot() }
        BarButton { visible: sddm.canPowerOff; label: "Shut Down"; onClicked: sddm.powerOff() }
    }
}
