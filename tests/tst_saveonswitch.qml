import QtQuick
import QtTest
import Trainingsplaner

// The forms beside a list (Sportler, Wettkampf, MAZ) save their edits when
// another entry is chosen, as the session panel does; the competitions to
// come stand under their own heading; the planned sessions up to today
// without an Ist are taken over at once.
Item {
    id: window
    width: 1300
    height: 900

    AthletesPage { id: athletes; anchors.fill: parent; visible: false }
    CompetitionsPage { id: competitions; anchors.fill: parent; visible: false; choosesAthlete: false }
    MazPane { id: maz; anchors.fill: parent; visible: false }
    Component { id: weekComponent; WeekPage { anchors.fill: parent } }

    TestCase {
        name: "SaveOnSwitch"
        when: windowShown

        function cleanup() {
            athletes.visible = false
            competitions.visible = false
            maz.visible = false
        }

        function test_athleteSavedWhenAnotherIsChosen() {
            const a = Store.saveAthlete({ lastName: "Wechsel", firstName: "Wanda", sex: 1 })
            const b = Store.saveAthlete({ lastName: "Wechsel", firstName: "Willi", sex: 0 })
            athletes.visible = true
            athletes.select(a)
            // The name field has the focus after choosing
            keyClick(Qt.Key_End)
            keyClick("x")
            verify(athletes.dirty)
            compare(findChild(athletes, "saveNote").visible, true)
            verify(athletes.leave())
            athletes.select(b)
            compare(Store.athletes.find(x => x.id === a).lastName, "Wechselx")
            compare(findChild(athletes, "saveNote").visible, false)
            Store.removeAthlete(a)
            Store.removeAthlete(b)
        }

        function test_athleteWithoutNameStays() {
            athletes.visible = true
            athletes.select("")
            keyClick(Qt.Key_Tab)   // to the first name
            keyClick("A")
            verify(athletes.dirty)
            // Not saved: the name is missing; the form stays and says so
            verify(!athletes.leave())
            verify(athletes.nameMissing)
            compare(athletes.selectedId, "")
            athletes.select("")
        }

        function test_competitionSavedToItsAthlete() {
            const a = Store.saveAthlete({ lastName: "Heber", firstName: "Hanna", sex: 1 })
            const b = Store.saveAthlete({ lastName: "Heber", firstName: "Hugo", sex: 0 })
            competitions.visible = true
            competitions.athleteId = a
            competitions.edit(null)
            waitForRendering(competitions)
            mouseClick(findChild(competitions, "snatch0"))
            keyClick("6"); keyClick("0")
            verify(competitions.dirty)
            // Chosen on another page meanwhile: the edit goes to Hanna
            competitions.athleteId = b
            compare(Store.competitions(a).length, 1)
            compare(Store.competitions(a)[0].snatch[0], 60)
            compare(Store.competitions(b).length, 0)
            verify(!competitions.dirty)
            Store.removeAthlete(a)
            Store.removeAthlete(b)
        }

        function test_comingCompetitionsHaveTheirHeading() {
            const a = Store.saveAthlete({ lastName: "Termin", firstName: "Tom", sex: 0 })
            const year = new Date().getFullYear()
            Store.saveCompetition({ athleteId: a, date: (year - 1) + "-03-07", name: "Alt", type: 1,
                                    snatch: [80, 0, 0], cleanJerk: [100, 0, 0] }, "", "")
            competitions.athleteId = a
            competitions.reload()
            // Only results: no headings
            compare(competitions.groupedList.length, 1)
            compare(competitions.groupedList[0].group, undefined)
            Store.saveCompetition({ athleteId: a, date: (year + 1) + "-12-20", name: "Neu", type: 3 }, "", "")
            competitions.reload()
            compare(competitions.groupedList.map(c => c.group), ["Anstehend", "Ergebnisse"])
            // The next one first among those to come
            Store.saveCompetition({ athleteId: a, date: (year + 1) + "-01-10", name: "Bald", type: 3 }, "", "")
            competitions.reload()
            compare(competitions.groupedList.map(c => c.name), ["Bald", "Neu", "Alt"])
            compare(findChild(competitions, "competitionList").sectionField, "group")
            Store.removeAthlete(a)
        }

        function test_mazSavedWhenAnotherIsChosen() {
            maz.visible = true
            maz.select("")
            const r = Plan.saveMaz({ name: "Wechsel-MAZ", shortName: "WM", sex: 0, from: "10/2031", to: "20/2031" })
            compare(r.error, "")
            maz.select(r.id)
            maz.dirty = true
            verify(maz.leave())
            verify(!maz.dirty)
            Plan.removeMaz(r.id)
        }

        function test_openSessionsTakenOverAtOnce() {
            const a = Store.saveAthlete({ lastName: "Offen", firstName: "Olga", sex: 1 })
            const monday = "2031-03-03"
            const line = { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }] }
            for (const day of [1, 3, 5])
                Store.saveSession(a, monday, "P", { day: day, number: 1, entries: [line] })
            // Monday was recorded already
            Store.saveSession(a, monday, "I", { day: 1, number: 1, entries: [line] })
            // Up to Wednesday: only Wednesday is open; Friday is still to come
            compare(Store.openSessions(a, monday, "2031-03-05"), [{ day: 3, number: 1 }])
            compare(Store.openSessions(a, monday, "2031-03-09").length, 2)
            compare(Store.openToActual(a, monday, "2031-03-05"), 1)
            verify(Store.session(a, monday, "I", 3, 1).exists)
            verify(!Store.session(a, monday, "I", 5, 1).exists)
            compare(Store.openSessions(a, monday, "2031-03-05").length, 0)
            // One step to undo
            verify(Store.undoLabel.indexOf("Ist = Plan") >= 0)
            Store.undo()
            verify(!Store.session(a, monday, "I", 3, 1).exists)
            verify(Store.session(a, monday, "I", 1, 1).exists)
            Store.removeAthlete(a)
        }

        // In the week: the open sessions named above the days, and taken
        // over with one click, which then shows the Ist
        function test_weekTakesOpenSessions() {
            const a = Store.saveAthlete({ lastName: "Offen", firstName: "Otto", sex: 0 })
            const monday = Store.mondayOf(Store.today())
            Store.saveSession(a, monday, "P", { day: 1, number: 1, entries: [
                { kind: 0, exercise: 1, steps: [{ kg: 50, reps: 3, sets: 2 }] } ] })
            const page = createTemporaryObject(weekComponent, window, { athleteId: a })
            page.monday = monday
            const bar = findChild(page, "openSessions")
            tryVerify(() => bar.visible)
            const openText = findChild(page, "openSessionsText")
            tryCompare(openText, "text", "1 Einheit ohne Ist: Mo")
            // Narrow: short, the days under the pointer
            window.width = 800
            tryCompare(openText, "text", "1 ohne Ist")
            window.width = 1300
            tryCompare(openText, "text", "1 Einheit ohne Ist: Mo")
            compare(page.variant, "P")
            const button = findChild(page, "openToActual")
            waitForRendering(page)
            mouseClick(button)
            tryCompare(page, "variant", "I")
            verify(Store.session(a, monday, "I", 1, 1).exists)
            tryVerify(() => !bar.visible)
            Store.removeAthlete(a)
        }
    }
}
