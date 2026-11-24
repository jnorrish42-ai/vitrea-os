/*
    Vitrea lock screen.

    The authentication logic follows KDE's own lock screen (plasma-desktop's
    LockScreenUi.qml / MainBlock.qml, GPL-2.0-or-later) line for line; only the
    look is Vitrea's: the photo stays sharp with a large clock while idle, and
    softly blurs behind a single password field when you start typing.

    Loaded by LockScreen.qml (see /usr/lib/vitrea/lockscreen-install). If this
    file ever fails to load, LockScreen.qml shows KDE's stock lock screen instead.
*/

import QtQml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as B
import Qt5Compat.GraphicalEffects

import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.accessibility
import org.kde.plasma.workspace.components as PW
import org.kde.plasma.workspace.keyboardlayout as Keyboards
import org.kde.plasma.private.keyboardindicator as KeyboardIndicator
import org.kde.kirigami as Kirigami
import org.kde.kscreenlocker as ScreenLocker
import org.kde.plasma.private.sessions
import org.kde.breeze.components

import "file:///usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen" as KdeLock

FocusScope {
    id: lockUi

    readonly property string kdeDir: "file:///usr/share/plasma/shells/org.kde.plasma.desktop/contents/lockscreen/"
    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    property bool expectingPrompt: false   // set for real when an authenticator is selected
    property bool showPrompt: false
    property bool passwordInputVisible: true
    property bool noPasswordUnlock: false  // unlocked without a prompt: show an Unlock button
    property string pendingPassword
    property date now: new Date()

    readonly property string font: "Inter"
    readonly property color ink: "#ffffff"
    readonly property color inkSoft: Qt.rgba(1, 1, 1, 0.72)

    focus: true
    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Complementary

    function handleMessage(msg) {
        if (!msg) {
            return;
        }
        if (!root.notification) {
            root.notification += msg;
        } else if (root.notification.includes(msg)) {
            root.notificationRepeated();
        } else {
            root.notification += "\n" + msg;
        }
        lockScreenRoot.uiVisible = true;
    }

    function startLogin() {
        const password = passwordBox.text;
        // also works round QTBUG-55460 (quitting with a focused TextField)
        unlockButton.forceActiveFocus();
        if (authenticator.pamTimeout) {
            lockUi.pendingPassword = password;
            centre.enabled = false;
        } else {
            authenticator.respond(password);
        }
    }

    // a quiet text-and-icon button for the bottom row
    component BarButton: Item {
        id: barButton
        property string label
        property string iconName
        signal clicked
        implicitWidth: row.implicitWidth + 24
        implicitHeight: 34
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: label
        Rectangle {
            anchors.fill: parent; radius: height / 2
            color: Qt.rgba(1, 1, 1, area.pressed ? 0.22 : (area.containsMouse || barButton.activeFocus ? 0.14 : 0))
            Behavior on color { ColorAnimation { duration: 120 } }
        }
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8
            Kirigami.Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: 18; height: 18
                source: barButton.iconName
                color: lockUi.ink
                isMask: true
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: barButton.label
                visible: text !== ""
                color: lockUi.inkSoft
                font.family: lockUi.font; font.pixelSize: 13; font.weight: Font.Medium
            }
        }
        MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: barButton.clicked() }
        Keys.onReturnPressed: clicked()
        Keys.onEnterPressed: clicked()
        Keys.onSpacePressed: clicked()
    }

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: lockUi.now = new Date()
    }

    Connections {
        target: authenticator
        function onFailed(kind) {
            if (kind != 0) { // noninteractive authenticators report their own errors
                return;
            }
            lockUi.handleMessage(i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Unlocking failed"));
            root.clearPassword();
            authenticator.startAuthenticating();
            notificationRemoveTimer.restart();
            rejectAnimation.start();
        }
        function onSucceeded() {
            // stops all pending authentication processes, preventing timeouts etc.
            authenticator.stopAuthenticating();
            if (!lockUi.expectingPrompt) {
                Qt.quit();
            }
            if (authenticator.hadPrompt) {
                Qt.quit();
            } else {
                lockUi.noPasswordUnlock = true;
                unlockNowButton.forceActiveFocus();
            }
        }
        function onInfoMessageChanged() { lockUi.handleMessage(authenticator.infoMessage); }
        function onErrorMessageChanged() { lockUi.handleMessage(authenticator.errorMessage); }
        function onPromptChanged() { lockUi.handleMessage(authenticator.prompt); }
        function onPromptForSecretChanged() {
            passwordBox.forceActiveFocus();
            if (lockUi.showPrompt) {
                lockUi.handleMessage(authenticator.promptForSecret);
            }
        }
        function onPamTimeoutChanged() {
            if (!authenticator.pamTimeout && lockUi.pendingPassword.length > 0) {
                authenticator.respond(lockUi.pendingPassword);
                lockUi.pendingPassword = "";
                centre.enabled = true;
            }
        }
    }

    SessionManagement { id: sessionManagement }
    AccessibilityStatus { id: accessibilityStatus }
    KeyboardIndicator.KeyState { id: capsLockState; key: Qt.Key_CapsLock }

    Connections {
        target: sessionManagement
        function onAboutToSuspend() { root.clearPassword(); }
    }

    RejectPasswordAnimation {
        id: rejectAnimation
        target: centre
    }

    MouseArea {
        id: lockScreenRoot

        property bool uiVisible: false
        property bool seenPositionChange: false
        property bool blockUI: containsMouse && (passwordBox.text.length > 0 || Keyboards.KWinVirtualKeyboard.visible)

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: uiVisible ? Qt.ArrowCursor : Qt.BlankCursor
        drag.filterChildren: true
        onPressed: uiVisible = true
        onPositionChanged: {
            uiVisible = seenPositionChange;
            seenPositionChange = true;
        }
        onUiVisibleChanged: {
            if (uiVisible) {
                Window.window.requestActivate();
            }
            if (blockUI) {
                fadeoutTimer.running = false;
            } else if (uiVisible) {
                fadeoutTimer.restart();
            }
            authenticator.startAuthenticating();
        }
        onBlockUIChanged: {
            if (blockUI) {
                fadeoutTimer.running = false;
                uiVisible = true;
            } else {
                fadeoutTimer.restart();
            }
        }

        Timer { // heart beat keeping the backend active while visible
            interval: 1000
            running: !authenticator.unlocked && lockScreenRoot.uiVisible
            repeat: true
            onTriggered: authenticator.startAuthenticating()
        }
        Timer {
            id: fadeoutTimer
            interval: 10000
            onTriggered: {
                if (!lockScreenRoot.blockUI) {
                    lockScreenRoot.uiVisible = false;
                }
            }
        }
        Timer {
            id: notificationRemoveTimer
            interval: 3000
            onTriggered: root.notification = ""
        }

        ScreenLocker.ActiveScreenMonitor {
            lockscreenState: ScreenLocker.LockscreenState
            window: lockScreenRoot.Window.window
            onActiveChanged: {
                if (!active) {
                    lockScreenRoot.uiVisible = false;
                }
            }
        }

        Keys.onEscapePressed: {
            // Escape turns the screen off in kscreenlocker; don't show the prompt for it
            if (uiVisible) {
                uiVisible = false;
                if (Keyboards.KWinVirtualKeyboard.visible) {
                    Keyboards.KWinVirtualKeyboard.active = false;
                }
                root.clearPassword();
            }
        }
        Keys.onPressed: event => {
            uiVisible = true;
            event.accepted = false;
        }

        // 0 while idle, 1 while the password prompt is up
        property real factor: uiVisible ? 1 : 0
        Behavior on factor { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

        // ---- the photo: sharp while idle, blurred behind the prompt ----
        FastBlur {
            anchors.fill: parent
            source: wallpaper
            radius: 72 * lockScreenRoot.factor
            visible: !lockUi.softwareRendering && !!wallpaper && lockScreenRoot.factor > 0.01
        }
        Rectangle { // darken for the prompt
            anchors.fill: parent
            color: "black"
            opacity: 0.30 * lockScreenRoot.factor
        }
        Rectangle { // a quiet shade at the top so the clock reads on bright skies
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: parent.height * 0.45
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.22) }
                GradientStop { position: 1; color: Qt.rgba(0, 0, 0, 0) }
            }
        }

        // ---- date and time ----
        Column {
            id: clock
            visible: config.alwaysShowClock || lockScreenRoot.uiVisible
            anchors.horizontalCenter: parent.horizontalCenter
            y: lockScreenRoot.height * (0.13 - 0.04 * lockScreenRoot.factor)
            spacing: -Math.round(timeText.font.pixelSize * 0.06)
            opacity: config.hideClockWhenIdle ? lockScreenRoot.factor : 1
            scale: 1 - 0.22 * lockScreenRoot.factor
            transformOrigin: Item.Top

            layer.enabled: !lockUi.softwareRendering
            layer.effect: DropShadow {
                radius: 18; samples: 25; verticalOffset: 1
                color: Qt.rgba(0, 0, 0, 0.28)
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: lockUi.now.toLocaleDateString(Qt.locale(), "dddd d MMMM")
                color: Qt.rgba(1, 1, 1, 0.92)
                font.family: lockUi.font
                font.pixelSize: Math.round(timeText.font.pixelSize * 0.17)
                font.weight: Font.DemiBold
            }
            Text {
                id: timeText
                anchors.horizontalCenter: parent.horizontalCenter
                readonly property bool twelveHour: Qt.locale().timeFormat(Locale.ShortFormat).toLowerCase().indexOf("a") >= 0
                text: Qt.formatTime(lockUi.now, twelveHour ? "h:mm" : "HH:mm")
                color: lockUi.ink
                font.family: lockUi.font
                font.pixelSize: Math.round(Math.min(lockScreenRoot.height * 0.17, lockScreenRoot.width * 0.13, 168))
                font.weight: Font.Medium
                font.letterSpacing: -font.pixelSize * 0.035
                font.features: { "tnum": 1 }
            }
        }

        // ---- user, password ----
        ColumnLayout {
            id: centre
            anchors.horizontalCenter: parent.horizontalCenter
            y: lockScreenRoot.height * 0.56 - height / 2 + (1 - lockScreenRoot.factor) * 24
            width: 300
            spacing: 0
            opacity: lockScreenRoot.factor
            visible: opacity > 0.001 || passwordBox.activeFocus   // keeps typing-to-wake working

            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 84; Layout.preferredHeight: 84
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    color: Qt.rgba(1, 1, 1, 0.16)
                    border.color: Qt.rgba(1, 1, 1, 0.30)
                }
                Text {
                    anchors.centerIn: parent
                    visible: userImage.status !== Image.Ready
                    text: (kscreenlocker_userName || "?").charAt(0).toUpperCase()
                    color: lockUi.ink
                    font.family: lockUi.font; font.pixelSize: 36; font.weight: Font.DemiBold
                }
                Image {
                    id: userImage
                    anchors.fill: parent
                    visible: false
                    sourceSize: Qt.size(168, 168)
                    fillMode: Image.PreserveAspectCrop
                    source: kscreenlocker_userImage !== ""
                            ? "file://" + kscreenlocker_userImage.split("/").map(encodeURIComponent).join("/") : ""
                }
                Rectangle { id: avatarMask; anchors.fill: parent; radius: width / 2; visible: false }
                OpacityMask {
                    anchors.fill: parent
                    source: userImage; maskSource: avatarMask
                    visible: userImage.status === Image.Ready && !lockUi.softwareRendering
                }
                Image { // software rendering: no masks, show the picture square-ish
                    anchors.fill: parent
                    visible: userImage.status === Image.Ready && lockUi.softwareRendering
                    source: userImage.source; fillMode: Image.PreserveAspectCrop
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 14
                text: kscreenlocker_userName
                color: lockUi.ink
                font.family: lockUi.font; font.pixelSize: 19; font.weight: Font.DemiBold
            }

            // password field with the unlock arrow inside it
            Item {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 18
                Layout.preferredWidth: 260; Layout.preferredHeight: 40
                visible: lockUi.passwordInputVisible && !lockUi.noPasswordUnlock

                B.TextField {
                    id: passwordBox
                    anchors.fill: parent
                    focus: true
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    passwordMaskDelay: 0
                    text: KdeLock.PasswordSync.password
                    // like KDE: blink the cursor only while the prompt is up
                    cursorVisible: lockScreenRoot.uiVisible && activeFocus
                    leftPadding: 18; rightPadding: 46
                    verticalAlignment: TextInput.AlignVCenter
                    color: lockUi.ink
                    selectionColor: Qt.rgba(1, 1, 1, 0.35)
                    selectedTextColor: lockUi.ink
                    font.family: lockUi.font
                    font.pixelSize: echoMode === TextInput.Password && text.length > 0 ? 11 : 15
                    font.letterSpacing: text.length > 0 ? 2 : 0
                    placeholderText: i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:placeholder in text field", "Password")
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.62)
                    background: Rectangle {
                        radius: height / 2
                        color: Qt.rgba(1, 1, 1, passwordBox.activeFocus ? 0.20 : 0.14)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, passwordBox.activeFocus ? 0.42 : 0.24)
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    onAccepted: {
                        if (lockScreenRoot.uiVisible) {
                            lockUi.startLogin();
                        }
                    }
                    Connections {
                        target: root
                        function onClearPassword() {
                            passwordBox.forceActiveFocus();
                            passwordBox.text = "";
                            passwordBox.text = Qt.binding(() => KdeLock.PasswordSync.password);
                        }
                        function onNotificationRepeated() {
                            rejectAnimation.start();
                        }
                    }
                }
                Binding {
                    target: KdeLock.PasswordSync
                    property: "password"
                    value: passwordBox.text
                }

                // the arrow: a white disc that appears once something is typed
                Rectangle {
                    id: unlockButton
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button accessible only", "Unlock")
                    anchors.right: parent.right; anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 28; height: 28; radius: 14
                    color: arrowArea.pressed ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.92)
                    opacity: passwordBox.text.length > 0 ? 1 : 0
                    scale: passwordBox.text.length > 0 ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                    Canvas {
                        anchors.centerIn: parent
                        width: 14; height: 14
                        onPaint: {
                            const c = getContext("2d");
                            c.reset();
                            c.strokeStyle = "#1c1b22"; c.lineWidth = 2; c.lineCap = "round"; c.lineJoin = "round";
                            c.beginPath(); c.moveTo(2, 7); c.lineTo(12, 7); c.moveTo(7.5, 2.5); c.lineTo(12, 7); c.lineTo(7.5, 11.5); c.stroke();
                        }
                    }
                    MouseArea {
                        id: arrowArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: lockUi.startLogin()
                    }
                    Keys.onEnterPressed: lockUi.startLogin()
                    Keys.onReturnPressed: lockUi.startLogin()
                }
            }

            // authenticated without a prompt (e.g. fingerprint): confirm with a button
            B.Button {
                id: unlockNowButton
                visible: lockUi.noPasswordUnlock
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 18
                text: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button no-password unlock", "Unlock")
                font.family: lockUi.font; font.pixelSize: 15; font.weight: Font.DemiBold
                leftPadding: 28; rightPadding: 28; topPadding: 9; bottomPadding: 9
                contentItem: Text { text: unlockNowButton.text; font: unlockNowButton.font; color: "#1c1b22"; horizontalAlignment: Text.AlignHCenter }
                background: Rectangle { radius: height / 2; color: unlockNowButton.down ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(1, 1, 1, 0.92) }
                onClicked: Qt.quit()
                Keys.onEnterPressed: clicked()
                Keys.onReturnPressed: clicked()
            }

            // status line: Caps Lock, "Unlocking failed", PAM prompts
            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 12
                Layout.preferredWidth: 340
                Layout.preferredHeight: Math.max(implicitHeight, 18)
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                textFormat: Text.PlainText
                color: lockUi.inkSoft
                font.family: lockUi.font; font.pixelSize: 13
                text: {
                    const parts = [];
                    if (capsLockState.locked) {
                        parts.push(i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Caps Lock is on"));
                    }
                    if (accessibilityStatus.slowKeysEnabled) {
                        parts.push(i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status", "Slow Keys are enabled"));
                    }
                    if (root.notification) {
                        parts.push(root.notification);
                    }
                    return parts.join(" • ");
                }
            }

            // more than one way to unlock (fingerprint, smartcard): pick one
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 6
                visible: authRepeater.count > 1
                Repeater {
                    id: authRepeater
                    model: ScreenLocker.AuthenticatorModel
                    delegate: PlasmaComponents3.Button {
                        required property int type
                        required property string iconName
                        required property bool passwordField
                        required property bool expectingPrompt
                        required property string tooltip
                        required property bool showPrompt
                        required property bool functional

                        onFunctionalChanged: {
                            if (functional) {
                                return;
                            }
                            root.notification = "";
                            lockUi.passwordInputVisible = false;
                            lockUi.handleMessage(i18ndc("plasma_shell_org.kde.plasma.desktop", "@info:status",
                                "This authentication method is not functioning correctly. Please try another method, and check your system configuration."));
                        }
                        enabled: functional
                        icon.name: iconName
                        icon.color: functional ? undefined : Kirigami.Theme.negativeTextColor
                        checked: authenticator.authenticator === type
                        onClicked: {
                            authenticator.authenticator = type;
                            root.notification = "";
                            lockUi.passwordInputVisible = passwordField;
                            lockUi.expectingPrompt = expectingPrompt;
                            lockUi.showPrompt = showPrompt;
                        }
                        PlasmaComponents3.ToolTip.text: tooltip
                        PlasmaComponents3.ToolTip.visible: hovered
                        Component.onCompleted: {
                            if (checked) {
                                clicked();
                            }
                        }
                    }
                }
            }

            // what's playing, with play/pause (KDE's media controls)
            Loader {
                Layout.topMargin: 22
                Layout.fillWidth: true
                Layout.preferredHeight: item ? item.implicitHeight : 0
                active: config.showMediaControls
                source: lockUi.kdeDir + "MediaControls.qml"
            }
        }

        // volume/brightness changes while locked
        Loader {
            z: 2
            active: root.viewVisible
            source: lockUi.kdeDir + "LockOsd.qml"
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Kirigami.Units.gridUnit * 4 }
        }

        // ---- bottom row: keyboard on the left, sleep / switch user in the middle, battery on the right ----
        Item {
            id: footer
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 18 }
            height: 34
            opacity: lockScreenRoot.factor
            visible: opacity > 0.001

            Row {
                anchors.left: parent.left
                spacing: 4
                BarButton {
                    iconName: Keyboards.KWinVirtualKeyboard.visible ? "input-keyboard-virtual-on" : "input-keyboard-virtual-off"
                    label: ""
                    Accessible.name: i18ndc("plasma_shell_org.kde.plasma.desktop", "Button to show/hide virtual keyboard", "Virtual Keyboard")
                    onClicked: {
                        if (Keyboards.KWinVirtualKeyboard.visible) {
                            Keyboards.KWinVirtualKeyboard.active = false;
                        } else {
                            passwordBox.forceActiveFocus();
                            Keyboards.KWinVirtualKeyboard.forceActivate();
                        }
                    }
                }
                BarButton {
                    id: layoutButton
                    visible: layoutSwitcher.hasMultipleKeyboardLayouts
                    iconName: "input-keyboard"
                    label: layoutSwitcher.layoutNames.shortName.toUpperCase()
                    onClicked: layoutSwitcher.keyboardLayout.switchToNextLayout()
                    PW.KeyboardLayoutSwitcher {
                        id: layoutSwitcher
                        anchors.fill: parent
                        acceptedButtons: Qt.NoButton
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                BarButton {
                    visible: sessionManagement.canSuspend
                    iconName: "system-suspend"
                    label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button", "Slee&p").replace("&", "")
                    onClicked: sessionManagement.suspend()
                }
                BarButton {
                    visible: sessionManagement.canHibernate
                    iconName: "system-suspend-hibernate"
                    label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button", "&Hibernate").replace("&", "")
                    onClicked: sessionManagement.hibernate()
                }
                BarButton {
                    visible: sessionManagement.canSwitchUser
                    iconName: "system-switch-user"
                    label: i18ndc("plasma_shell_org.kde.plasma.desktop", "@action:button", "Switch &User").replace("&", "")
                    onClicked: sessionManagement.switchUser()
                }
            }

            Battery {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
