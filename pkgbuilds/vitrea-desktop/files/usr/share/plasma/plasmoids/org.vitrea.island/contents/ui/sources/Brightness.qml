// Screen brightness changes (powerdevil).
import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin

Item {
    id: src
    signal changed(real level)
    property bool ready: false
    Timer { interval: 2500; running: true; onTriggered: src.ready = true }
    ScreenBrightnessControl { id: sbc }
    Instantiator {
        model: sbc.displays
        delegate: QtObject {
            required property int brightness
            required property int maxBrightness
            onBrightnessChanged: if (src.ready && maxBrightness > 0) src.changed(brightness / maxBrightness)
        }
    }
}
