// An image clipped to a rounded rectangle (plain `clip` only cuts square corners).
// Uses a shader mask; if shader effects are unavailable it falls back to the plain image.
import QtQuick
import QtQuick.Effects

Item {
    id: ri
    property alias source: img.source
    property real radius: 12
    readonly property alias status: img.status

    Image {
        id: img
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(Math.max(1, ri.width * 2), Math.max(1, ri.height * 2))
        visible: !fx.visible
        layer.enabled: fx.visible
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: ri.radius
        visible: false
        layer.enabled: true
        layer.smooth: true
    }
    MultiEffect {
        id: fx
        anchors.fill: parent
        source: img
        visible: img.status === Image.Ready && GraphicsInfo.api !== GraphicsInfo.Software
        maskEnabled: true
        maskSource: mask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
