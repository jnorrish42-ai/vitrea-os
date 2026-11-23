// Yumeka Kuroha, Vitrea's desktop companion (plain QtQuick, so it can be previewed anywhere).
import QtQuick

Item {
    id: yu
    property color accent: "#cba6f7"
    property string imageDir: Qt.resolvedUrl("../images/")
    property string pose: "idle"
    property string line: ""
    property int pokes: 0
    readonly property bool night: { var h = clock.now.getHours(); return h >= 23 || h < 5 }

    QtObject {
        id: clock
        property date now: new Date()
    }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    function greeting() {
        var h = new Date().getHours()
        if (h >= 23 || h < 5) return "Zzz… it's late. Get some rest~"
        if (h < 12) return "Good morning! ☀"
        if (h < 18) return "Hey! What are we doing today?"
        return "Good evening~"
    }
    readonly property var reactions: [
        { pose: "peace",     line: "Peace! ✌" },
        { pose: "cheer",     line: "You've got this!" },
        { pose: "heart",     line: "Thanks for using Vitrea ♡" },
        { pose: "surprised", line: "Whoa!" },
        { pose: "curious",   line: "Hmm? What's that?" },
        { pose: "lookup",    line: "The sky's pretty tonight…" }
    ]
    property int nextReaction: 0

    function say(p, l, ms) {
        pose = p; line = l
        bubble.opacity = 1
        settle.interval = ms || 4200
        settle.restart()
        hop.restart()
    }
    function poke() {
        pokes += 1
        pokeReset.restart()
        if (pokes >= 5) { say("pout", "Hey! Stop poking me!", 3600); pokes = 0; return }
        var r = reactions[nextReaction % reactions.length]
        nextReaction += 1
        say(r.pose, r.line)
    }
    function rest() {
        pose = night ? "sleepy" : "idle"
        bubble.opacity = 0
    }
    Timer { id: settle; onTriggered: yu.rest() }
    Timer { id: pokeReset; interval: 3000; onTriggered: yu.pokes = 0 }
    // every now and then she glances around on her own
    Timer {
        interval: 95000; running: true; repeat: true
        onTriggered: if (yu.pose === "idle" && !yu.night) yu.say(Math.random() < 0.5 ? "lookup" : "curious", "", 2600)
    }
    onNightChanged: if (pose === "idle" || pose === "sleepy") rest()
    Component.onCompleted: { rest(); greetLater.start() }
    Timer { id: greetLater; interval: 1800; onTriggered: yu.say(yu.night ? "sleepy" : "peace", yu.greeting(), 5000) }

    // ---- the character ----
    Item {
        id: body
        width: sprite.paintedWidth; height: sprite.paintedHeight
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: hopY.y
        transform: Scale { id: squash; origin.x: body.width / 2; origin.y: body.height; xScale: 1; yScale: 1 }

        Image {
            id: sprite
            width: yu.width * 0.62
            height: yu.height * 0.84
            fillMode: Image.PreserveAspectFit
            horizontalAlignment: Image.AlignRight
            verticalAlignment: Image.AlignBottom
            anchors.right: parent.right; anchors.bottom: parent.bottom
            source: yu.imageDir + yu.pose + ".png"
            smooth: true; mipmap: true
        }
        // soft contact shadow
        Rectangle {
            width: body.width * 0.7; height: 10; radius: 5
            anchors.horizontalCenter: body.horizontalCenter; anchors.top: body.bottom; anchors.topMargin: -6 - hopY.y
            color: Qt.rgba(0, 0, 0, 0.35 - hopY.y / 200)
            z: -1
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: yu.poke()
            onEntered: if (!bubble.opacity) yu.say(yu.pose, yu.night ? "Mmm… five more minutes…" : yu.greeting(), 2600)
        }
    }
    // breathing: a tiny vertical squash
    SequentialAnimation {
        running: true; loops: Animation.Infinite
        NumberAnimation { target: squash; property: "yScale"; to: 1.012; duration: 1700; easing.type: Easing.InOutSine }
        NumberAnimation { target: squash; property: "yScale"; to: 1.0; duration: 1700; easing.type: Easing.InOutSine }
    }
    // a springy hop when she reacts
    QtObject { id: hopY; property real y: 0 }
    SequentialAnimation {
        id: hop
        NumberAnimation { target: hopY; property: "y"; to: 18; duration: 160; easing.type: Easing.OutQuad }
        NumberAnimation { target: hopY; property: "y"; to: 0; duration: 420; easing.type: Easing.OutBounce }
    }

    // ---- glass speech bubble ----
    Item {
        id: bubble
        opacity: 0
        visible: opacity > 0 && yu.line !== ""
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        width: Math.min(yu.width * 0.72, label.implicitWidth + 36)
        height: label.implicitHeight + 24
        anchors.right: body.left; anchors.rightMargin: -body.width * 0.12
        anchors.bottom: body.top; anchors.bottomMargin: -body.height * 0.16
        scale: opacity * 0.08 + 0.92
        transformOrigin: Item.BottomRight

        Rectangle {
            anchors.fill: parent; radius: 18
            color: Qt.rgba(0.08, 0.07, 0.13, 0.72)
            border.color: Qt.rgba(yu.accent.r, yu.accent.g, yu.accent.b, 0.85)
            Rectangle {
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1 }
                height: parent.height * 0.5; radius: 17
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.14) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0) }
                }
            }
        }
        Rectangle {   // little tail toward her
            width: 12; height: 12; rotation: 45
            color: Qt.rgba(0.08, 0.07, 0.13, 0.72)
            border.color: Qt.rgba(yu.accent.r, yu.accent.g, yu.accent.b, 0.85)
            anchors.right: parent.right; anchors.rightMargin: 22
            anchors.top: parent.bottom; anchors.topMargin: -7
            z: -1
        }
        Text {
            id: label
            anchors.centerIn: parent
            width: Math.min(implicitWidth, yu.width * 0.72 - 36)
            text: yu.line
            wrapMode: Text.WordWrap
            color: "#f2f0ff"
            font.family: "Inter"; font.pixelSize: 15; font.weight: Font.Medium
        }
    }
}
