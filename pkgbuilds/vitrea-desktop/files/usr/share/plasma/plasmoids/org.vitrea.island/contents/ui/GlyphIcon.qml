// Small vector icons drawn with Canvas (font glyphs/emoji differ between systems).
import QtQuick

Canvas {
    id: gi
    property string kind: "play"   // back fwd play pause speaker muted sun bolt battery bell timer
    property color color: "white"
    property real fill: 1          // battery level 0..1
    implicitWidth: 20; implicitHeight: 20
    onKindChanged: requestPaint()
    onColorChanged: requestPaint()
    onFillChanged: requestPaint()
    onWidthChanged: requestPaint()
    onPaint: {
        var c = getContext("2d"), w = width, h = height
        c.reset(); c.fillStyle = color; c.strokeStyle = color; c.lineJoin = "round"; c.lineCap = "round"
        function tri(x0, dir) {
            c.beginPath()
            if (dir > 0) { c.moveTo(x0, h * 0.2); c.lineTo(x0 + w * 0.46, h * 0.5); c.lineTo(x0, h * 0.8) }
            else { c.moveTo(x0 + w * 0.46, h * 0.2); c.lineTo(x0, h * 0.5); c.lineTo(x0 + w * 0.46, h * 0.8) }
            c.closePath(); c.fill()
        }
        function speaker() {
            c.beginPath(); c.moveTo(w * 0.08, h * 0.38); c.lineTo(w * 0.28, h * 0.38); c.lineTo(w * 0.52, h * 0.16)
            c.lineTo(w * 0.52, h * 0.84); c.lineTo(w * 0.28, h * 0.62); c.lineTo(w * 0.08, h * 0.62); c.closePath(); c.fill()
        }
        c.lineWidth = Math.max(1.5, w * 0.09)
        switch (kind) {
        case "fwd": tri(w * 0.04, 1); tri(w * 0.5, 1); break
        case "back": tri(w * 0.04, -1); tri(w * 0.5, -1); break
        case "play": c.beginPath(); c.moveTo(w * 0.24, h * 0.12); c.lineTo(w * 0.86, h * 0.5); c.lineTo(w * 0.24, h * 0.88); c.closePath(); c.fill(); break
        case "pause": c.fillRect(w * 0.22, h * 0.14, w * 0.18, h * 0.72); c.fillRect(w * 0.60, h * 0.14, w * 0.18, h * 0.72); break
        case "speaker":
            speaker()
            c.beginPath(); c.arc(w * 0.52, h * 0.5, w * 0.2, -0.8, 0.8); c.stroke()
            c.beginPath(); c.arc(w * 0.52, h * 0.5, w * 0.36, -0.8, 0.8); c.stroke(); break
        case "muted":
            speaker()
            c.beginPath(); c.moveTo(w * 0.66, h * 0.34); c.lineTo(w * 0.94, h * 0.66); c.moveTo(w * 0.94, h * 0.34); c.lineTo(w * 0.66, h * 0.66); c.stroke(); break
        case "sun":
            c.beginPath(); c.arc(w * 0.5, h * 0.5, w * 0.2, 0, Math.PI * 2); c.fill()
            for (var i = 0; i < 8; i++) {
                var a = i * Math.PI / 4
                c.beginPath(); c.moveTo(w * 0.5 + Math.cos(a) * w * 0.32, h * 0.5 + Math.sin(a) * h * 0.32)
                c.lineTo(w * 0.5 + Math.cos(a) * w * 0.45, h * 0.5 + Math.sin(a) * h * 0.45); c.stroke()
            }
            break
        case "bolt":
            c.beginPath(); c.moveTo(w * 0.58, h * 0.04); c.lineTo(w * 0.18, h * 0.56); c.lineTo(w * 0.46, h * 0.56)
            c.lineTo(w * 0.38, h * 0.96); c.lineTo(w * 0.82, h * 0.40); c.lineTo(w * 0.54, h * 0.40); c.closePath(); c.fill(); break
        case "battery":
            c.lineWidth = Math.max(1.2, w * 0.07)
            c.strokeRect(w * 0.06, h * 0.28, w * 0.78, h * 0.44)
            c.fillRect(w * 0.86, h * 0.40, w * 0.08, h * 0.2)
            c.fillRect(w * 0.12, h * 0.34, w * 0.66 * Math.max(0, Math.min(1, fill)), h * 0.32); break
        case "bell":
            c.beginPath(); c.moveTo(w * 0.2, h * 0.72); c.quadraticCurveTo(w * 0.28, h * 0.6, w * 0.28, h * 0.44)
            c.quadraticCurveTo(w * 0.3, h * 0.14, w * 0.5, h * 0.14); c.quadraticCurveTo(w * 0.7, h * 0.14, w * 0.72, h * 0.44)
            c.quadraticCurveTo(w * 0.72, h * 0.6, w * 0.8, h * 0.72); c.closePath(); c.fill()
            c.beginPath(); c.arc(w * 0.5, h * 0.8, w * 0.09, 0, Math.PI * 2); c.fill(); break
        case "timer":
            c.beginPath(); c.arc(w * 0.5, h * 0.56, w * 0.36, 0, Math.PI * 2); c.stroke()
            c.beginPath(); c.moveTo(w * 0.5, h * 0.56); c.lineTo(w * 0.5, h * 0.34); c.stroke()
            c.fillRect(w * 0.4, h * 0.02, w * 0.2, h * 0.1); break
        }
    }
}
