import QtQuick
import calamares.slideshow 1.0
Presentation {
    id: presentation
    function onActivate() { }
    function onLeave() { }
    Timer { interval: 12000; running: presentation.activatedInCalamares; repeat: true; onTriggered: presentation.goToNextSlide() }
    Slide { Image { anchors.fill: parent; fillMode: Image.PreserveAspectFit; smooth: true; source: "01-welcome.png" } }
    Slide { Image { anchors.fill: parent; fillMode: Image.PreserveAspectFit; smooth: true; source: "02-apps.png" } }
    Slide { Image { anchors.fill: parent; fillMode: Image.PreserveAspectFit; smooth: true; source: "03-safe.png" } }
    Slide { Image { anchors.fill: parent; fillMode: Image.PreserveAspectFit; smooth: true; source: "04-yours.png" } }
}
