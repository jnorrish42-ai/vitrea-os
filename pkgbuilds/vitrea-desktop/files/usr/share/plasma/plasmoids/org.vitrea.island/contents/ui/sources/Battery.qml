// Plugged in / unplugged, and low-battery warnings (powermanagement data engine).
import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: src
    signal changed(bool plugged, int percent)
    property bool ready: false
    property int warnedAt: 101
    Timer { interval: 3000; running: true; onTriggered: src.ready = true }
    P5Support.DataSource {
        id: pm
        engine: "powermanagement"
        connectedSources: ["AC Adapter", "Battery"]
        readonly property bool hasBattery: data["Battery"] ? !!data["Battery"]["Has Battery"] : false
        readonly property bool plugged: data["AC Adapter"] ? !!data["AC Adapter"]["Plugged in"] : false
        readonly property int percent: data["Battery"] ? (data["Battery"]["Percent"] || 0) : 0
        onPluggedChanged: { src.warnedAt = 101; if (src.ready && hasBattery) src.changed(plugged, percent) }
        onPercentChanged: {
            if (!src.ready || !hasBattery || plugged) return
            if ((percent <= 20 && src.warnedAt > 20) || (percent <= 10 && src.warnedAt > 10)) {
                src.warnedAt = percent
                src.changed(false, percent)
            }
        }
    }
}
