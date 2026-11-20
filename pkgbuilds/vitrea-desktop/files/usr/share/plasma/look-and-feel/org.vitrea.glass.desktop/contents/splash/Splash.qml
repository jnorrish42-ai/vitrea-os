// Vitrea Liquid login splash: the same scene as the boot splash, so boot -> login -> desktop
// feels like one continuous animation. KSplash sets "stage" as the desktop loads.
import QtQuick

Rectangle {
    id: root
    property int stage
    gradient: Gradient {
        GradientStop { position: 0; color: "#0b0b14" }
        GradientStop { position: 1; color: "#1b1530" }
    }

    // drifting petals
    Repeater {
        model: 34
        Image {
            id: petal
            property real speed: 18 + Math.random() * 40
            property real sway: Math.random() * 6.28
            source: "images/petal" + (index % 3) + ".png"
            x: Math.random() * root.width
            y: root.height * Math.random()
            opacity: 0.15 + Math.random() * 0.4
            NumberAnimation on y {
                from: root.height + 40; to: -40; loops: Animation.Infinite
                duration: (root.height + 80) / petal.speed * 1000
                running: true
            }
            transform: Translate { x: Math.sin(petal.y / 90 + petal.sway) * 24 }
        }
    }

    Item {
        id: centre
        width: 240; height: 240
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.height * 0.06
        opacity: 0

        Image {
            id: halo
            source: "images/halo.png"
            anchors.centerIn: parent
            width: 620; height: 620
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { from: 0.45; to: 0.85; duration: 1600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 0.85; to: 0.45; duration: 1600; easing.type: Easing.InOutSine }
            }
        }
        // comet orbit
        Repeater {
            id: ring
            model: 16
            property real head: 0
            Image {
                source: "images/dot.png"
                property real a: index / 16 * Math.PI * 2 - Math.PI / 2
                x: centre.width / 2 + Math.cos(a) * 206 - width / 2
                y: centre.height / 2 + Math.sin(a) * 206 - height / 2
                opacity: {
                    var d = ((ring.head - index) % 16 + 16) % 16
                    return Math.max(0, 1 - d / 7) * 0.9
                }
            }
            NumberAnimation on head { from: 0; to: 16; duration: 2200; loops: Animation.Infinite; running: true }
        }
        Image {
            id: logo
            source: "images/logo-240.png"
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 28 * (1 - centre.opacity)
            smooth: true
        }
    }

    // progress: a thin glass line that fills with the stages
    Rectangle {
        id: track
        width: 320; height: 8; radius: 4
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: centre.bottom; anchors.topMargin: 110
        color: Qt.rgba(1, 1, 1, 0.14)
        border.color: Qt.rgba(1, 1, 1, 0.27)
        opacity: centre.opacity
        Rectangle {
            height: parent.height; radius: 4
            width: Math.max(8, parent.width * Math.min(1, root.stage / 6))
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: "#cba6f7" }
                GradientStop { position: 1; color: "#89b4fa" }
            }
        }
    }

    NumberAnimation {
        id: intro
        target: centre; property: "opacity"; from: 0; to: 1
        duration: 1100; easing.type: Easing.OutCubic
        running: true
    }
}
