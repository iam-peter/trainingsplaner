import QtQuick
import TrainingsplanerStyle as Styles
import QtQuick.Controls
import Trainingsplaner

// The load over the weeks of a cycle (Plan.loadCourse), the sawtooth of
// raised and lowered weeks. Above, the weight of one exercise: its heaviest
// (BW) and mean (MHG) weight as the ITP's target (dashed), as done (solid),
// as planned for the weeks ahead (thin), and an ideal line straight from
// the first week done to the last target. Below, the reps of K1-7: the
// target as bars in the colour of the week's load (h / m / g), done as
// dots. Lowered weeks are shaded, today is marked.
Item {
    id: chart

    property var course: ({})
    property int hoverIndex: -1

    readonly property int count: (course.labels || []).length
    readonly property var s: Styles.TokenInterface.semantics
    readonly property color bwColor: "#c2410c"
    readonly property color mhgColor: "#0f766e"
    readonly property var loadColor: ({ h: "#5b6b7f", m: "#9aa8b8", g: "#d5dde6" })

    onCourseChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
    onHoverIndexChanged: canvas.requestPaint()

    // The plots' places, shared by the drawing and the pointer
    readonly property real plotLeft: 48
    readonly property real plotRight: 14
    readonly property real plotWidth: Math.max(1, width - plotLeft - plotRight)
    readonly property real slot: count > 0 ? plotWidth / count : plotWidth
    readonly property real topTop: 22
    readonly property real topHeight: Math.max(60, (height - topTop - 34) * 0.66)
    readonly property real bottomTop: topTop + topHeight + 34
    readonly property real bottomHeight: Math.max(30, height - bottomTop - 22)
    function xAt(i) { return plotLeft + slot * (i + 0.5) }

    // First and last index with a value
    function firstOf(list) {
        for (let i = 0; i < list.length; ++i)
            if (list[i] !== undefined && list[i] !== null)
                return i
        return -1
    }
    function lastOf(list) {
        for (let i = list.length - 1; i >= 0; --i)
            if (list[i] !== undefined && list[i] !== null)
                return i
        return -1
    }
    // The ideal line: from the first week done (else the first target) to
    // the last target
    function ideal(key) {
        const t = course.target ? course.target[key] : []
        const a = course.actual ? course.actual[key] : []
        const i1 = lastOf(t)
        let i0 = firstOf(a)
        let v0 = i0 >= 0 ? a[i0] : null
        if (i0 < 0) {
            i0 = firstOf(t)
            v0 = i0 >= 0 ? t[i0] : null
        }
        return i0 >= 0 && i1 > i0 ? { i0: i0, v0: v0, i1: i1, v1: t[i1] } : null
    }
    // Planned values shown: the weeks from today on that are not done yet
    function plannedAt(key, i) {
        const p = course.planned ? course.planned[key][i] : null
        if (p === undefined || p === null)
            return null
        if (course.actual[key][i] !== undefined && course.actual[key][i] !== null)
            return null
        const today = course.todayIndex
        if (today >= 0)
            return i >= today ? p : null
        return course.mondays[i] > Store.today() ? p : null
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (chart.count === 0)
                return
            const c = chart.course
            const n = chart.count

            // Range of the weights: all values and the ideal lines
            let lo = Infinity, hi = -Infinity
            for (const set of [c.target, c.actual, c.planned])
                for (const k of ["mhg", "bw"])
                    for (const v of set[k])
                        if (v !== undefined && v !== null) {
                            lo = Math.min(lo, v)
                            hi = Math.max(hi, v)
                        }
            if (lo === Infinity) {
                lo = 0
                hi = 100
            }
            const step = 5
            lo = Math.floor((lo - 3) / step) * step
            hi = Math.ceil((hi + 3) / step) * step
            const yTop = v => chart.topTop + chart.topHeight * (1 - (v - lo) / (hi - lo))

            let whMax = 0
            for (const set of [c.target, c.actual, c.planned])
                for (const v of set.wh)
                    if (v)
                        whMax = Math.max(whMax, v)
            whMax = whMax > 0 ? Math.ceil(whMax * 1.1 / 50) * 50 : 100
            const yBottom = v => chart.bottomTop + chart.bottomHeight * (1 - v / whMax)

            // Lowered weeks shaded, in both plots
            for (let i = 0; i < n; ++i) {
                if (c.load[i] === "g") {
                    ctx.fillStyle = Qt.rgba(0.44, 0.54, 0.66, 0.12)
                    ctx.fillRect(chart.plotLeft + chart.slot * i, chart.topTop, chart.slot,
                                 chart.bottomTop + chart.bottomHeight - chart.topTop)
                }
            }
            // The week under the pointer
            if (chart.hoverIndex >= 0) {
                ctx.fillStyle = Qt.rgba(0.5, 0.5, 0.5, 0.10)
                ctx.fillRect(chart.plotLeft + chart.slot * chart.hoverIndex, chart.topTop, chart.slot,
                             chart.bottomTop + chart.bottomHeight - chart.topTop)
            }

            // Grid and axis numbers
            ctx.font = "11px sans-serif"
            ctx.fillStyle = chart.s.text_muted
            ctx.strokeStyle = chart.s.stroke_subtle
            ctx.lineWidth = 1
            ctx.textAlign = "right"
            ctx.textBaseline = "middle"
            const tick = (hi - lo) > 40 ? 10 : 5
            for (let v = lo; v <= hi; v += tick) {
                const y = Math.round(yTop(v)) + 0.5
                ctx.beginPath(); ctx.moveTo(chart.plotLeft, y); ctx.lineTo(chart.width - chart.plotRight, y); ctx.stroke()
                ctx.fillText(String(v), chart.plotLeft - 6, y)
            }
            for (const v of [0, whMax / 2, whMax]) {
                const y = Math.round(yBottom(v)) + 0.5
                ctx.beginPath(); ctx.moveTo(chart.plotLeft, y); ctx.lineTo(chart.width - chart.plotRight, y); ctx.stroke()
                ctx.fillText(String(Math.round(v)), chart.plotLeft - 6, y)
            }
            ctx.textAlign = "left"
            ctx.textBaseline = "alphabetic"
            ctx.fillText(c.unit === "%" ? "%" : "kg", 4, chart.topTop - 8)
            ctx.fillText("WH K1-7", 4, chart.bottomTop - 10)

            // Week numbers
            ctx.textAlign = "center"
            ctx.textBaseline = "top"
            const every = chart.slot < 26 ? 2 : 1
            for (let i = 0; i < n; i += every)
                ctx.fillText(c.labels[i], chart.xAt(i), chart.bottomTop + chart.bottomHeight + 6)

            // Today
            if (c.todayIndex >= 0) {
                const x = Math.round(chart.xAt(c.todayIndex)) + 0.5
                ctx.save()
                ctx.setLineDash([3, 3])
                ctx.strokeStyle = chart.s.text_muted
                ctx.beginPath(); ctx.moveTo(x, chart.topTop); ctx.lineTo(x, chart.bottomTop + chart.bottomHeight); ctx.stroke()
                ctx.restore()
                ctx.textBaseline = "bottom"
                ctx.fillText("heute", x, chart.topTop - 2)
            }

            // Reps: target bars in the load's colour, done as dots, planned hollow
            const barW = Math.max(3, chart.slot * 0.6)
            ctx.textBaseline = "bottom"
            for (let i = 0; i < n; ++i) {
                const t = c.target.wh[i]
                if (t) {
                    ctx.fillStyle = chart.loadColor[c.load[i]] || "#cbd5e1"
                    ctx.fillRect(chart.xAt(i) - barW / 2, yBottom(t), barW, yBottom(0) - yBottom(t))
                }
                // The load's letter at the top of its bar, clear of the dots
                if (c.load[i] !== "" && barW >= 10) {
                    ctx.textBaseline = "top"
                    ctx.fillStyle = c.load[i] === "g" || !t ? chart.s.text_default : "white"
                    ctx.fillText(c.load[i], chart.xAt(i), (t ? yBottom(t) : yBottom(0) - 14) + 2)
                }
            }
            for (let i = 0; i < n; ++i) {
                const a = c.actual.wh[i]
                if (a) {
                    ctx.fillStyle = chart.s.text_default
                    ctx.beginPath(); ctx.arc(chart.xAt(i), yBottom(a), 3.5, 0, 2 * Math.PI); ctx.fill()
                }
                const p = chart.plannedAt("wh", i)
                if (p) {
                    ctx.strokeStyle = chart.s.text_muted
                    ctx.lineWidth = 1.5
                    ctx.beginPath(); ctx.arc(chart.xAt(i), yBottom(p), 3.5, 0, 2 * Math.PI); ctx.stroke()
                }
            }

            // Weights: per measure the ideal line, the target, the plan, the Ist
            function line(values, color, width, dash, dots, hollow) {
                ctx.save()
                ctx.strokeStyle = color
                ctx.fillStyle = color
                ctx.lineWidth = width
                ctx.setLineDash(dash)
                ctx.beginPath()
                let started = false
                for (let i = 0; i < n; ++i) {
                    const v = values[i]
                    if (v === undefined || v === null)
                        continue
                    if (!started) { ctx.moveTo(chart.xAt(i), yTop(v)); started = true }
                    else ctx.lineTo(chart.xAt(i), yTop(v))
                }
                ctx.stroke()
                ctx.setLineDash([])
                if (dots > 0) {
                    for (let i = 0; i < n; ++i) {
                        const v = values[i]
                        if (v === undefined || v === null)
                            continue
                        ctx.beginPath()
                        ctx.arc(chart.xAt(i), yTop(v), dots, 0, 2 * Math.PI)
                        if (hollow) {
                            ctx.fillStyle = chart.s.background_default
                            ctx.fill()
                            ctx.lineWidth = 1.5
                            ctx.stroke()
                        } else {
                            ctx.fill()
                        }
                    }
                }
                ctx.restore()
            }
            for (const [key, color] of [["mhg", chart.mhgColor], ["bw", chart.bwColor]]) {
                const id = chart.ideal(key)
                if (id) {
                    ctx.save()
                    ctx.strokeStyle = color
                    ctx.globalAlpha = 0.7
                    ctx.lineWidth = 1.2
                    ctx.setLineDash([1.5, 3])
                    ctx.beginPath()
                    ctx.moveTo(chart.xAt(id.i0), yTop(id.v0))
                    ctx.lineTo(chart.xAt(id.i1), yTop(id.v1))
                    ctx.stroke()
                    ctx.restore()
                }
                line(c.target[key], color, 1.6, [6, 4], 3.5, true)
                const planned = []
                for (let i = 0; i < n; ++i)
                    planned.push(chart.plannedAt(key, i))
                ctx.globalAlpha = 0.55
                line(planned, color, 1.4, [], 2.5, false)
                ctx.globalAlpha = 1
                line(c.actual[key], color, 2.6, [], 4.5, false)
            }
        }
    }

    // The week under the pointer, with its numbers
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: (mouse) => {
            const i = Math.floor((mouse.x - chart.plotLeft) / chart.slot)
            chart.hoverIndex = mouse.x >= chart.plotLeft && i >= 0 && i < chart.count ? i : -1
        }
        onExited: chart.hoverIndex = -1
    }
    Rectangle {
        visible: chart.hoverIndex >= 0
        readonly property real anchorX: chart.xAt(Math.max(0, chart.hoverIndex))
        x: anchorX + 12 + width > chart.width ? anchorX - 12 - width : anchorX + 12
        y: chart.topTop + 4
        width: tip.implicitWidth + 16
        height: tip.implicitHeight + 10
        radius: 4
        color: chart.s.background_elevated
        border.color: chart.s.stroke_subtle
        Label {
            id: tip
            anchors.centerIn: parent
            font.pixelSize: 11
            textFormat: Text.PlainText
            text: {
                const i = chart.hoverIndex
                const c = chart.course
                if (i < 0 || !c.labels)
                    return ""
                const v = x => x === undefined || x === null ? "–" : x
                const u = c.unit === "%" ? " %" : ""
                return "KW " + c.labels[i] + (c.load[i] ? " · Belastung " + c.load[i] : "")
                       + "\nBW   Ziel " + v(c.target.bw[i]) + u + " · Ist " + v(c.actual.bw[i]) + u + " · Plan " + v(c.planned.bw[i]) + u
                       + "\nMHG  Ziel " + v(c.target.mhg[i]) + u + " · Ist " + v(c.actual.mhg[i]) + u + " · Plan " + v(c.planned.mhg[i]) + u
                       + "\nWH K1-7  Ziel " + v(c.target.wh[i]) + " · Ist " + v(c.actual.wh[i]) + " · Plan " + v(c.planned.wh[i])
            }
        }
    }

    Label {
        anchors.centerIn: parent
        visible: chart.count === 0
        text: "Keine Wochen."
        color: chart.s.text_muted
    }
}
