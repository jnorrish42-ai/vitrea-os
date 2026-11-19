import QtQuick
import calamares.slideshow 1.0
Presentation {
    id: presentation
    function onActivate() { timer.running = true }
    function onLeave() { timer.running = false }
    Rectangle { anchors.fill: parent; color: "#2a2f5c"; z: -1 }
    Timer { id: timer; interval: 9000; running: true; repeat: true; onTriggered: presentation.goToNextSlide() }
    Slide { Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; smooth: true; source: "01-welcome.png" } }
    Slide { Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; smooth: true; source: "02-apps.png" } }
    Slide { Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; smooth: true; source: "03-safe.png" } }
    Slide { Image { anchors.fill: parent; fillMode: Image.PreserveAspectCrop; smooth: true; source: "04-yours.png" } }
}
