import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner

// The RO's proposal per ITP cell: shown grey in an empty cell, taken one
// cell at a time (Ctrl+Enter, or the menu) or a whole week; what
// "Vorlage" would make of it
Item {
    width: 1366
    height: 860

    ItpGrid {
        id: grid
        anchors.fill: parent
    }

    TestCase {
        name: "Proposal"
        when: windowShown

        readonly property int proposalRole: Qt.UserRole + 6
        property string mazId
        property string athlete
        property string monday

        function initTestCase() {
            const r = Plan.saveMaz({ name: "Vorschlag", sex: 0, from: "10/2036", to: "22/2036", template: "U17" })
            compare(r.error, "")
            mazId = r.id
            monday = Plan.maz(mazId).fromMonday
            athlete = Store.saveAthlete({ lastName: "Vorschlag", firstName: "Vera", sex: 1 })
            Plan.saveMazAthlete({ mazId: mazId, athleteId: athlete, targetSnatch: 80, targetCleanJerk: 100 })
            grid.owner = athlete
            grid.mazId = mazId
            grid.fromMonday = monday
            grid.weeks = 13
            // Reißen WH, MHG, BW (0-2), K1 (3), K1-7, K1-5, Bel., WK (4-7)
            grid.exercises = [1, -1]
        }

        function cleanupTestCase() {
            grid.owner = ""
            Plan.removeMaz(mazId)
            Store.removeAthlete(athlete)
        }

        function model() { return grid.model }
        function display(r, c) { return model().data(model().index(r, c), Qt.DisplayRole) }
        function proposal(r, c) { return model().data(model().index(r, c), proposalRole) }
        function cellText(r, c) {
            const item = findChild(grid, "itpTable").itemAtCell(Qt.point(c, r))
            return item.children.find(x => x.text !== undefined && x.font !== undefined && x.visible).text
        }

        function test_1_shown() {
            verify(model().proposals)
            // Week 1 of the U17: 65/70 % of 80 kg, K1 70 WH, load m
            compare(display(0, 1), "")
            compare([proposal(0, 1), proposal(0, 2), proposal(0, 3)], ["52", "55", "70"])
            compare(proposal(0, 6), "m")
            compare(proposal(12, 7), "HWK")
            // The exercise has no WH in the RTK, the sums no proposal
            compare(proposal(0, 0), "")
            compare(proposal(0, 4), "")
            compare(proposal(13, 1), "")
            // An empty cell shows it, grey
            const table = findChild(grid, "itpTable")
            tryVerify(() => table.itemAtCell(Qt.point(1, 0)) !== null)
            const item = table.itemAtCell(Qt.point(1, 0))
            compare(item.proposal, "52")
            // A RO itself has none, nor an ITP of an own range
            const ro = Qt.createQmlObject("import Trainingsplaner; ItpModel {}", this)
            ro.owner = Plan.roOwner(mazId)
            ro.mazId = mazId
            ro.fromMonday = monday
            ro.weeks = 13
            ro.exercises = [1]
            verify(!ro.proposals)
            ro.owner = athlete
            ro.mazId = ""
            verify(!ro.proposals)
            ro.destroy()
        }

        function test_2_cell() {
            // The menu takes one cell; BW brings its reps and sets
            verify(model().takeProposal(0, 2))
            compare(display(0, 2), "55")
            const t = Plan.itpForWeek(athlete, monday, 1)
            compare([t.bw, t.repsSets, t.mhg], [55, "3/2", 0])
            // Ctrl+Enter in the editor takes the MHG
            const table = findChild(grid, "itpTable")
            table.focusCell(0, 1)
            tryVerify(() => table.itemAtCell(Qt.point(1, 0)).editor !== null)
            const editor = table.itemAtCell(Qt.point(1, 0)).editor
            tryVerify(() => editor.activeFocus)
            compare(editor.placeholderText, "52")
            keyClick(Qt.Key_Return, Qt.ControlModifier)
            compare(display(0, 1), "52")
            // Leaving the cell keeps it
            keyClick(Qt.Key_Escape)
            table.focusCell(5, 3)
            compare(display(0, 1), "52")
            compare(Plan.itpForWeek(athlete, monday, 1).mhg, 52)
            // Nothing to take where the RO has nothing
            verify(!model().takeProposal(0, 0))
        }

        function test_3_week() {
            // Week 2: MHG, BW (over the coach's 50), K1 and Bel. come
            // from the RO; the exercise's WH and the WK, which it has
            // not, stay
            verify(model().setData(model().index(1, 2), "50", Qt.UserRole + 1))
            compare(model().takeWeek(1), 4)
            compare([display(1, 1), display(1, 2), display(1, 3), display(1, 6)], ["52", "57", "90", "h"])
            compare(model().takeWeek(1), 0)
            // Week 3 untouched
            compare(display(2, 1), "")
        }

        function test_4_menu() {
            const table = findChild(grid, "itpTable")
            const item = table.itemAtCell(Qt.point(3, 3))
            mouseClick(item, item.width / 2, item.height / 2, Qt.RightButton)
            const menu = findChild(grid, "proposalMenu")
            tryCompare(menu, "opened", true)
            const take = findChild(menu.contentItem, "takeProposal") || menu.itemAt(0)
            verify(take.enabled)
            compare(take.text, "Vorschlag der RO übernehmen: " + proposal(3, 3))
            take.triggered()
            menu.close()
            compare(display(3, 3), proposal(3, 3))
        }
    }
}
