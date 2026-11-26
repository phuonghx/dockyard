import QtQuick

// Recent history of one number. Right-aligned so new samples slide in from the edge.
Canvas {
    id: s
    property var values: []
    property real ceiling: 1            // value that maps to full height
    property int capacity: 60
    property color stroke: Theme.acc
    onValuesChanged: requestPaint()
    onStrokeChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    renderTarget: Canvas.Image

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const n = values.length
        if (n < 2 || width < 4) return
        const step = width / (capacity - 1)
        const top = 2, bottom = height - 1.5
        const y = v => bottom - Math.min(1, Math.max(0, v / Math.max(ceiling, 1e-9))) * (bottom - top)
        const x = i => width - (n - 1 - i) * step
        ctx.beginPath()
        ctx.moveTo(x(0), y(values[0]))
        for (let i = 1; i < n; i++) ctx.lineTo(x(i), y(values[i]))
        ctx.lineWidth = 1.5
        ctx.lineJoin = "round"
        ctx.strokeStyle = stroke
        ctx.stroke()
        ctx.lineTo(x(n - 1), height)
        ctx.lineTo(x(0), height)
        ctx.closePath()
        const g = ctx.createLinearGradient(0, 0, 0, height)
        g.addColorStop(0, Qt.rgba(stroke.r, stroke.g, stroke.b, 0.22))
        g.addColorStop(1, Qt.rgba(stroke.r, stroke.g, stroke.b, 0.0))
        ctx.fillStyle = g
        ctx.fill()
    }
}
