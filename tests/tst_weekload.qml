import QtQuick
import QtTest
import Trainingsplaner

// The week's load (Belastung, the ITP's Bel. column) set from the week
// plan: h, m or g, the chosen one again takes it back
Item {
    width: 1366
    height: 860

    ItpModel {
        id: itp
        weeks: 1
        exercises: [1]
    }

    // As the planning page does: the grid reads the plan again on a change
    Connections {
        target: Plan
        function onChanged() { itp.reload() }
    }

    WeekPage {
        id: page
        anchors.fill: parent
        athleteId: "test_tina"
    }

    TestCase {
        name: "WeekLoad"
        when: windowShown

        readonly property int editRole: Qt.UserRole + 1

        function cleanup() {
            Plan.setWeekLoad("test_tina", page.monday, "")
            itp.owner = ""
        }

        // The ITP's own values of the week stay, and its grid shows the
        // load; a later save there keeps it (columns: exercise 1's WH, MHG,
        // BW, then Bel. and WK)
        function test_itpFollows() {
            itp.owner = "test_tina"
            itp.fromMonday = page.monday
            verify(itp.setData(itp.index(0, 4), "WK-1", editRole))
            mouseClick(findChild(page, "weekLoad_g"))
            tryCompare(page.context, "loadText", "g")
            compare(page.context.position, "WK-1")
            compare(itp.data(itp.index(0, 3)), "g")
            verify(itp.setData(itp.index(0, 4), "WK-2", editRole))
            compare(Store.weekContext("test_tina", page.monday).loadText, "g")
            // And the other way: the ITP's change shows in the week plan
            // when it is shown again
            verify(itp.setData(itp.index(0, 3), "m", editRole))
            page.visible = false
            page.visible = true
            compare(page.context.loadText, "m")
            verify(itp.setData(itp.index(0, 4), "", editRole))
        }

        function test_setFromWeekPlan() {
            const g = findChild(page, "weekLoad_g"), h = findChild(page, "weekLoad_h")
            verify(g && h)
            compare(page.context.loadText, "")
            verify(!g.highlighted)

            mouseClick(g)
            tryCompare(page.context, "loadText", "g")
            verify(g.highlighted)
            verify(!h.highlighted)
            // Stored for the ITP: g is 1
            compare(Store.weekContext("test_tina", page.monday).load, 1)

            mouseClick(h)
            tryCompare(page.context, "loadText", "h")
            verify(!g.highlighted)

            // The chosen one again: none
            mouseClick(h)
            tryCompare(page.context, "loadText", "")
            verify(!h.highlighted)
        }

        // Another week has its own load
        function test_perWeek() {
            mouseClick(findChild(page, "weekLoad_m"))
            tryCompare(page.context, "loadText", "m")
            const monday = page.monday
            page.monday = Store.addWeeks(monday, 1)
            compare(page.context.loadText, "")
            page.monday = monday
            compare(page.context.loadText, "m")
        }

        // The week note's row has no label any more: the placeholder says
        // it. The load sits in its place.
        function test_noNoteLabel() {
            let note = null
            const find = (item) => {
                if (item.placeholderText === "Bemerkung zur Woche")
                    note = item
                for (const child of item.children)
                    find(child)
            }
            find(page)
            verify(note)
            let row = note
            while (row && !row.children.some(c => c.objectName === "weekLoad" || c.children.some(d => d.objectName === "weekLoad")))
                row = row.parent
            verify(row, "the load is in the note's row")
            const texts = []
            const walk = (item) => {
                if (item.text !== undefined)
                    texts.push(item.text)
                for (const child of item.children)
                    walk(child)
            }
            walk(row)
            verify(texts.indexOf("Bemerkung:") < 0, texts)
            verify(texts.indexOf("Belastung") >= 0, texts)
        }
    }
}
