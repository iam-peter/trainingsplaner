import QtQuick
import QtTest
import Trainingsplaner

// A new MAZ from a template of the RTK: the form takes the template's
// name, weeks and phases from "von" on, "Hinzufügen" writes its
// Rahmenorientierung, and "Vorlage" makes an athlete's ITP of it
Item {
    width: 1366
    height: 860

    // As in the window, which chooses the athlete for all pages
    PlanningPage {
        id: planning
        anchors.fill: parent
        choosesAthlete: false
    }

    ItpModel { id: grid }

    TestCase {
        name: "Rtk"
        when: windowShown

        property string mazId
        property string athlete

        function cleanupTestCase() {
            if (mazId !== "")
                Plan.removeMaz(mazId)
            if (athlete !== "")
                Store.removeAthlete(athlete)
        }

        function test_templates() {
            const t = Plan.rtkTemplates()
            compare(t.map(x => x.key), ["U13", "U15", "U17", "U20"])
            compare(t.map(x => x.weeks), [6, 13, 13, 17])
            compare(t[2].text, "RTK U17 (13 Wochen)")
            // U15 and U17: six weeks Grundlagen-, four Aufbau-, three
            // Leistungsausprägungsphase; U13 none, U20 left to the coach
            compare([t[2].buildUp, t[2].peak], [7, 11])
            compare([t[0].buildUp, t[0].peak], [0, 0])
            compare([t[3].buildUp, t[3].peak], [0, 0])
        }

        function test_newMazFromTemplate() {
            planning.showTab("maz")
            const pane = findChild(planning, "mazPane")
            pane.select("")
            const box = findChild(pane, "templateBox")
            verify(box.enabled)
            findChild(pane, "mazFrom").text = "10/2031"
            box.currentIndex = 3
            box.activated(3)
            compare(findChild(pane, "mazName").text, "RTK U17")
            compare(findChild(pane, "mazTo").text, "22/2031")
            compare(findChild(pane, "mazBuildUp").text, "16/2031")
            compare(findChild(pane, "mazPeak").text, "20/2031")
            // Another "von": the weeks and phases follow
            const from = findChild(pane, "mazFrom")
            from.text = "11/2031"
            from.textEdited()
            compare(findChild(pane, "mazTo").text, "23/2031")
            compare(findChild(pane, "mazPeak").text, "21/2031")

            pane.save()
            compare(pane.error, "")
            mazId = pane.mazId
            verify(mazId !== "")
            // Saved: no template box for an existing MAZ
            verify(!box.enabled)

            // The RO in percent: week 1 of the U17's, 65/70 at 3 reps in 2 sets
            const ro = Plan.roOwner(mazId)
            const monday = Plan.maz(mazId).fromMonday
            const snatch = Plan.itpForWeek(ro, monday, 1)
            compare([snatch.mhg, snatch.bw, snatch.repsSets], [65, 70, "3/2"])
            compare(Plan.itpForWeek(ro, monday, -1).wh, 70)
            compare(Plan.itpForWeek(ro, monday, -5).wh, 100)
            // The last week, the main competition's
            const last = Store.addWeeks(monday, 12)
            compare(Plan.itpForWeek(ro, last, 1).bw, 100)

            // An athlete's ITP from it, with targets of 100 kg the percent
            athlete = Store.saveAthlete({ lastName: "Vorlage", firstName: "Vera", sex: 0 })
            Plan.saveMazAthlete({ mazId: mazId, athleteId: athlete, targetSnatch: 100, targetCleanJerk: 120 })
            verify(Plan.itpFromRo(mazId, athlete))
            const c = Plan.loadCourse(athlete, mazId, "", 0, 1, "kg")
            compare(c.labels.length, 13)
            compare(c.load.join(""), "mhhghhghhghmg")
            compare(Plan.itpForWeek(athlete, monday, 1).bw, 70)
            compare(Plan.itpForWeek(athlete, last, 1).bw, 100)
        }

        // The complexes as the RTK plans them: WH only, and the week's
        // K1-7 and K1-5 as their sums, with the RTK's averages
        function test_complexesAndSums() {
            const r = Plan.saveMaz({ name: "RTK U17", sex: 0, from: "30/2031", to: "42/2031", template: "U17" })
            compare(r.error, "")
            const editRole = Qt.UserRole + 1
            grid.owner = Plan.roOwner(r.id)
            grid.mazId = r.id
            grid.fromMonday = Plan.maz(r.id).fromMonday
            grid.weeks = 13
            grid.exercises = [-1, -2, -3, -4, -5, -6, -7]
            // One column per complex, then K1-7, K1-5, Bel., WK
            compare(grid.columnCount(), 7 + 2 + 2)
            compare(grid.columnInfo(0).title, "K1")
            compare(grid.columnInfo(1).title, "K2")
            compare(grid.columnInfo(7).title, "K1-7")
            compare(grid.columnInfo(8).title, "K1-5")
            verify(grid.columnInfo(7).readOnly && !grid.columnInfo(0).readOnly)
            const at = (r, c) => grid.data(grid.index(r, c), Qt.DisplayRole)
            compare([at(0, 7), at(0, 8)], ["390", "330"])
            // "insgesamt" of the RTK's U17: 358 and 298
            compare([at(13, 7), at(13, 8)], ["358", "298"])
            // A complex changed: the sums follow; the sums are not typed
            verify(grid.setData(grid.index(0, 0), "80", editRole))
            compare([at(0, 7), at(0, 8)], ["400", "340"])
            verify(!grid.setData(grid.index(0, 7), "500", editRole))
            compare(at(0, 7), "400")
            verify(grid.setData(grid.index(0, 0), "70", editRole))
            // An exercise keeps WH, MHG and BW
            grid.exercises = [1, -1]
            compare(grid.columnCount(), 3 + 1 + 2 + 2)
            compare(grid.columnInfo(2).sub, "BW %")
            compare(grid.columnInfo(3).title, "K1")
            grid.owner = ""
            Plan.removeMaz(r.id)
        }

        // Without a template nothing changes in the form
        function test_noTemplate() {
            const pane = findChild(planning, "mazPane")
            pane.select("")
            const box = findChild(pane, "templateBox")
            compare(box.currentIndex, 0)
            compare(findChild(pane, "mazTo").text, "")
            box.activated(0)
            compare(findChild(pane, "mazTo").text, "")
            compare(findChild(pane, "mazName").text, "")
        }
    }
}
