// Output volume changes (plasma-pa).
import QtQuick
import org.kde.plasma.private.volume

Item {
    id: src
    signal changed(real level, bool muted)
    property bool ready: false
    readonly property var sink: PreferredDevice.sink
    Timer { interval: 2500; running: true; onTriggered: src.ready = true }   // ignore startup values
    function emit() { if (ready && sink) changed(sink.volume / 65536, sink.muted) }
    Connections {
        target: src.sink
        function onVolumeChanged() { src.emit() }
        function onMutedChanged() { src.emit() }
    }
}
