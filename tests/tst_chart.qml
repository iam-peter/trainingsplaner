import QtQuick
import QtTest
import Trainingsplaner

// Hovering over a chart shows the values of that week
Item {
    width: 800
    height: 400

    TrendChart {
        id: chart
        anchors.fill: parent
        labels: ["45", "46", "47", "48"]
        lines: [{ name: "MHG", color: "red", values: [60, null, 62.5, 64] }]
        bars: [{ name: "WH", color: "gray", values: [120, 90, 0, 110] }]
    }

    TestCase {
        name: "Chart"
        when: windowShown

        function lines() {
            const box = findChild(chart, "valueBox")
            const list = []
            const walk = item => {
                for (const c of item.children) {
                    if (c.objectName === "valueLine")
                        list.push(c.text)
                    walk(c)
                }
            }
            walk(box)
            return list
        }

        function test_hoverShowsValues() {
            waitForRendering(chart)
            tryVerify(() => chart.plot !== null)
            const p = chart.plot
            const box = findChild(chart, "valueBox")
            verify(!box.visible)

            mouseMove(chart, p.left + p.slot * 2.5, p.top + 20)
            compare(chart.hoverIndex, 2)
            verify(box.visible)
            compare(lines(), ["MHG: 62,5", "WH: 0"])

            mouseMove(chart, p.left + p.slot * 1.5, p.top + 20)
            compare(lines(), ["MHG: –", "WH: 90"])

            // The box stays inside the chart at the right edge
            mouseMove(chart, p.left + p.slot * 3.9, p.top + 20)
            verify(box.x + box.width <= chart.width)

            mouseMove(chart, 2, 2)   // outside the plot
            compare(chart.hoverIndex, -1)
            verify(!box.visible)
        }
    }
}
