// Installer slideshow: plain text on a dark background, shown while Vitrea installs.
import QtQuick
import calamares.slideshow 1.0

Presentation {
    id: presentation
    function onActivate() { timer.running = true }
    function onLeave() { timer.running = false }
    Rectangle { anchors.fill: parent; color: "#1c1c1e"; z: -1 }
    Timer { id: timer; interval: 10000; running: true; repeat: true; onTriggered: presentation.goToNextSlide() }

    component Page: Slide {
        id: page
        property string heading
        property string body
        Column {
            anchors.centerIn: parent
            width: Math.min(parent.width * 0.75, 640)
            spacing: 14
            Text { width: parent.width; text: page.heading; color: "#f2f2f2"; font.family: "Inter"; font.pixelSize: 30; font.weight: Font.DemiBold; wrapMode: Text.WordWrap }
            Text { width: parent.width; text: page.body; color: "#b4b4b8"; font.family: "Inter"; font.pixelSize: 17; lineHeight: 1.3; wrapMode: Text.WordWrap }
        }
    }

    Page { heading: "Installing Vitrea"; body: "This takes about 10 minutes. When it's done, restart and take out the USB stick." }
    Page { heading: "Apps"; body: "Discover has thousands of free apps, including Firefox, Spotify, Steam and LibreOffice." }
    Page { heading: "Updates you can undo"; body: "Vitrea saves a copy of the system before every update. If an update ever causes trouble, pick an earlier version from the menu that appears when the computer starts." }
    Page { heading: "Other systems stay"; body: "If you kept another system, like Windows or Arch, choose it in the same start-up menu." }
    Page { heading: "Two desktops"; body: "Plasma is the standard desktop. Hyprland, set up by 43PR, arranges windows automatically and is mostly used with the keyboard. Pick it at the bottom left of the login screen." }
}
