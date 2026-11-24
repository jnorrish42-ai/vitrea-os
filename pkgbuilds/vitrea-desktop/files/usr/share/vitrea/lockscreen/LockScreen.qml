/*
    Vitrea: installed over KDE's lockscreen/LockScreen.qml by /usr/lib/vitrea/lockscreen-install
    (KDE's original is kept next to it as LockScreen.qml.kde).

    Shows Vitrea's lock screen, and falls back to KDE's own (LockScreenUi.qml in this
    folder) if Vitrea's can't be loaded, so a broken theme can never lock anyone out.
    Based on KDE's LockScreen.qml, SPDX-FileCopyrightText: 2014 Aleix Pol Gonzalez, GPL-2.0-or-later.
*/

import QtQuick

Item {
    id: root
    property bool debug: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()

    // These are magical properties that kscreenlocker looks for
    property bool viewVisible: false

    LayoutMirroring.enabled: Application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    implicitWidth: 800
    implicitHeight: 600

    Loader {
        id: vitrea
        anchors.fill: parent
        focus: status === Loader.Ready
        source: "file:///usr/share/vitrea/lockscreen/VitreaLock.qml"
        onStatusChanged: {
            if (status === Loader.Error) {
                console.warn("Vitrea lock screen failed to load, using KDE's");
                stock.active = true;
            }
        }
    }

    Loader {
        id: stock
        anchors.fill: parent
        active: false
        focus: active
        source: "LockScreenUi.qml"
    }
}
