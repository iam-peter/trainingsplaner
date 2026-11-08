import QtQuick
import QtQuick.Controls

// A simple chart over categories (weeks, dates): bars on the right axis
// (volume), lines on the left axis (intensity), optional linear trends and
// horizontal reference lines.
//   lines:      [{ name, color, values: [number|null], trend: bool }]
//   bars:       [{ name, color, values: [number] }]
//   references: [{ name, color, value }]
Item {
    id: chart

    property var labels: []
    property var lines: []
    property var bars: []
    property var references: []
    property string leftTitle
    property string rightTitle
    property string title
    property bool showValues: false

    implicitWidth: 600
    implicitHeight: 320

    onLabelsChanged: canvas.requestPaint()
    onLinesChanged: canvas.requestPaint()
    onBarsChanged: canvas.requestPaint()
    onReferencesChanged: canvas.requestPaint()
    onShowValuesChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()

    // Least squares line through the defined points: [a, b] for a + b*x
    function regression(values) {
        let n = 0, sx = 0, sy = 0, sxx = 0, sxy = 0
        for (let i = 0; i < values.length; ++i) {
            const y = values[i]
            if (y === null || y === undefined || isNaN(y))
                continue
            n++; sx += i; sy += y; sxx += i * i; sxy += i * y
        }
        if (n < 2)
            return null
        const b = (n * sxy - sx * sy) / (n * sxx - sx * sx)
        return [(sy - b * sx) / n, b]
    }

    function niceRange(lo, hi) {
        if (lo === hi) { lo -= 1; hi += 1 }
        const span = hi - lo
        const step0 = Math.pow(10, Math.floor(Math.log10(span / 5)))
        const step = [1, 2, 2.5, 5, 10].map(f => f * step0).find(s => span / s <= 6) || step0 * 10
        return { lo: Math.floor(lo / step) * step, hi: Math.ceil(hi / step) * step, step: step }
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderTarget: Canvas.Image

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.fillStyle = palette.base
            ctx.fillRect(0, 0, width, height)
            const font = "12px Inter, sans-serif"
            ctx.font = font
            const n = chart.labels.length
            const titleH = chart.title !== "" ? 22 : 0
            const legendH = 22
            const left = 52, right = chart.bars.length > 0 ? 52 : 16, top = 12 + titleH, bottom = 44 + legendH
            const w = width - left - right, h = height - top - bottom
            if (n === 0 || w <= 0 || h <= 0) {
                ctx.fillStyle = palette.placeholderText
                ctx.fillText("Keine Daten", width / 2 - 30, height / 2)
                return
            }
            if (chart.title !== "") {
                ctx.fillStyle = palette.text
                ctx.font = "bold 13px Inter, sans-serif"
                ctx.fillText(chart.title, left, 16)
                ctx.font = font
            }
            const slot = w / n
            const xAt = i => left + slot * (i + 0.5)

            // Value ranges
            let lo = Infinity, hi = -Infinity
            for (const l of chart.lines)
                for (const v of l.values)
                    if (v !== null && v !== undefined && !isNaN(v)) { lo = Math.min(lo, v); hi = Math.max(hi, v) }
            for (const r of chart.references) { lo = Math.min(lo, r.value); hi = Math.max(hi, r.value) }
            const hasLines = lo !== Infinity
            const L = hasLines ? niceRange(Math.max(0, lo - (hi - lo) * 0.1), hi + (hi - lo) * 0.1) : null
            let bhi = 0
            for (const b of chart.bars)
                for (const v of b.values)
                    bhi = Math.max(bhi, v || 0)
            const B = chart.bars.length > 0 ? niceRange(0, Math.max(1, bhi)) : null
            const yL = v => top + h - (v - L.lo) / (L.hi - L.lo) * h
            const yB = v => top + h - v / B.hi * h

            // Grid and axes
            ctx.strokeStyle = palette.mid
            ctx.lineWidth = 1
            ctx.fillStyle = palette.placeholderText
            const axis = L || B
            for (let v = axis.lo; v <= axis.hi + 1e-9; v += axis.step) {
                const y = L ? yL(v) : yB(v)
                ctx.globalAlpha = 0.35
                ctx.beginPath(); ctx.moveTo(left, y); ctx.lineTo(left + w, y); ctx.stroke()
                ctx.globalAlpha = 1
                ctx.textAlign = "right"
                ctx.fillText(Math.round(v * 10) / 10, left - 6, y + 4)
            }
            if (L && B) {
                ctx.textAlign = "left"
                for (let v = 0; v <= B.hi + 1e-9; v += B.step)
                    ctx.fillText(Math.round(v), left + w + 6, yB(v) + 4)
            }
            ctx.textAlign = "center"
            const every = Math.max(1, Math.ceil(n / Math.max(1, Math.floor(w / 56))))
            for (let i = 0; i < n; i += every)
                ctx.fillText(chart.labels[i], xAt(i), top + h + 16)
            ctx.save()
            ctx.translate(14, top + h / 2); ctx.rotate(-Math.PI / 2)
            ctx.fillText(L ? chart.leftTitle : chart.rightTitle, 0, 0)
            ctx.restore()
            if (L && B) {
                ctx.save()
                ctx.translate(width - 10, top + h / 2); ctx.rotate(Math.PI / 2)
                ctx.fillText(chart.rightTitle, 0, 0)
                ctx.restore()
            }

            // Bars side by side within the slot
            const nb = chart.bars.length
            chart.bars.forEach((b, k) => {
                ctx.fillStyle = b.color
                ctx.globalAlpha = 0.55
                const bw = Math.max(2, slot * 0.7 / nb)
                for (let i = 0; i < n; ++i) {
                    const v = b.values[i] || 0
                    if (v <= 0)
                        continue
                    const x = left + slot * i + slot * 0.15 + bw * k
                    ctx.fillRect(x, yB(v), bw - 1, top + h - yB(v))
                    if (chart.showValues) {
                        ctx.globalAlpha = 1
                        ctx.fillStyle = palette.text
                        ctx.fillText(v, x + bw / 2, yB(v) - 3)
                        ctx.fillStyle = b.color
                        ctx.globalAlpha = 0.55
                    }
                }
                ctx.globalAlpha = 1
            })

            // Reference lines
            for (const r of chart.references) {
                ctx.strokeStyle = r.color
                ctx.setLineDash([6, 4])
                ctx.lineWidth = 1.5
                ctx.beginPath(); ctx.moveTo(left, yL(r.value)); ctx.lineTo(left + w, yL(r.value)); ctx.stroke()
                ctx.setLineDash([])
            }

            // Lines with points, gaps where there is no value
            for (const l of chart.lines) {
                ctx.strokeStyle = l.color
                ctx.fillStyle = l.color
                ctx.lineWidth = 2
                ctx.beginPath()
                let open = false
                for (let i = 0; i < n; ++i) {
                    const v = l.values[i]
                    if (v === null || v === undefined || isNaN(v)) { open = false; continue }
                    if (!open) ctx.moveTo(xAt(i), yL(v)); else ctx.lineTo(xAt(i), yL(v))
                    open = true
                }
                ctx.stroke()
                for (let i = 0; i < n; ++i) {
                    const v = l.values[i]
                    if (v === null || v === undefined || isNaN(v)) continue
                    ctx.beginPath(); ctx.arc(xAt(i), yL(v), 3, 0, 2 * Math.PI); ctx.fill()
                    if (chart.showValues) {
                        ctx.fillStyle = palette.text
                        ctx.fillText(v, xAt(i), yL(v) - 7)
                        ctx.fillStyle = l.color
                    }
                }
                if (l.trend) {
                    const r = chart.regression(l.values)
                    if (r) {
                        ctx.setLineDash([3, 3])
                        ctx.lineWidth = 1.5
                        ctx.beginPath()
                        ctx.moveTo(xAt(0), yL(r[0])); ctx.lineTo(xAt(n - 1), yL(r[0] + r[1] * (n - 1)))
                        ctx.stroke()
                        ctx.setLineDash([])
                    }
                }
            }

            // Legend
            let lx = left
            const ly = height - 10
            ctx.textAlign = "left"
            const items = chart.lines.map(l => ({ name: l.name + (l.trend ? " (mit Trend)" : ""), color: l.color, bar: false }))
                .concat(chart.bars.map(b => ({ name: b.name, color: b.color, bar: true })))
                .concat(chart.references.map(r => ({ name: r.name, color: r.color, bar: false })))
            for (const it of items) {
                ctx.fillStyle = it.color
                ctx.globalAlpha = it.bar ? 0.55 : 1
                ctx.fillRect(lx, ly - 9, 14, it.bar ? 10 : 3)
                ctx.globalAlpha = 1
                ctx.fillStyle = palette.text
                ctx.fillText(it.name, lx + 20, ly)
                lx += 28 + ctx.measureText(it.name).width
            }
        }
    }
}
