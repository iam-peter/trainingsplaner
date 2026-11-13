import QtQuick
import QtTest
import Trainingsplaner

// The DGJ's youth rules where competitions are: the DM Jugend norm of the
// athlete's class, one competition per week up to AK 17, the youth
// competitions to pick, the norms editable
Item {
    id: window
    width: 1400
    height: 900

    CompetitionDateDialog {
        id: dialog
    }

    TestCase {
        name: "Youth"
        when: windowShown

        property string athlete
        // AK 16 in 2026 and 2027 is AK 17
        readonly property int year: new Date().getFullYear()

        function initTestCase() {
            athlete = Store.saveAthlete({ lastName: "Jugend", firstName: "Jonas", sex: 0,
                                          born: "01.05." + (year - 16) })
            verify(athlete !== "")
            Store.saveCompetition({ athleteId: athlete, date: year + "-03-07", name: "LM", bodyWeight: "87,5",
                                    snatch: [60, 65, 0], cleanJerk: [80, 85, 0] }, "", "")
        }

        function cleanupTestCase() {
            for (const c of Store.competitions(athlete))
                Store.removeCompetition(athlete, c.date, c.time)
            Store.removeAthlete(athlete)
            Store.dmNorms = []
        }

        function test_status() {
            const s = Store.youthStatus(athlete, year + "-04-01")
            compare(s.ageClass, 16)
            verify(s.youth)
            compare(s.weightClass, "-89")
            verify(s.dm.applies)
            compare(s.dm.norm, 188)
            compare(s.dm.best, 150)
            verify(!s.dm.reached)
            verify(s.dm.text.indexOf("noch 38 kg") > 0)
            // Before this year's first competition there is none yet
            verify(Store.youthStatus(athlete, year + "-02-01").dm.text.indexOf("noch kein Zweikampf") > 0)
        }

        function test_editedNorm() {
            const norms = Store.dmNorms.map(n => n.sex === 0 && n.weightClass === "-89"
                                            ? { sex: 0, weightClass: "-89", total: 150 } : n)
            Store.dmNorms = norms
            const s = Store.youthStatus(athlete, year + "-04-01")
            verify(s.dm.reached)
            verify(s.dm.text.indexOf("erfüllt") > 0)
            Store.dmNorms = []
            compare(Store.youthStatus(athlete, year + "-04-01").dm.norm, 188)
        }

        function test_onePerWeek() {
            // 7 March is a Saturday: the Sunday is the same week, the Monday not
            verify(Store.weekConflict(athlete, year + "-03-08", "").indexOf("LM") > 0 || new Date(year, 2, 8).getDay() === 1)
            compare(Store.weekConflict(athlete, "07.03." + year, year + "-03-07"), "")
            const monday = new Date(year, 2, 7)
            while (monday.getDay() !== 1)
                monday.setDate(monday.getDate() + 1)
            const iso = monday.getFullYear() + "-03-" + String(monday.getDate()).padStart(2, "0")
            compare(Store.weekConflict(athlete, iso, ""), "")
        }

        function test_monthShowsNormAndWarning() {
            const d1 = (year + 1) + "-12-11"
            const d2 = (year + 1) + "-12-12"
            Store.saveCompetitionDate(athlete, d1, 1, "DM Jugend (AK 16–17)", "Berlin", "", "")
            Store.saveCompetitionDate(athlete, d2, 0, "Pokal", "", "", "")
            const m = Store.month(athlete, (year + 1) + "-12-01", false)
            const dm = m.upcoming.find(c => c.date === d1)
            verify(dm.norm.indexOf("Norm DM Jugend -89 kg: 188 kg") === 0)
            // Two in one week, at AK 17
            verify(dm.warning.indexOf("Zwei Wettkämpfe") === 0)
            Store.removeCompetition(athlete, d1, "")
            Store.removeCompetition(athlete, d2, "")
        }

        function test_dialogOffersYouthCompetitions() {
            dialog.show(null, (year + 1) + "-03-10", athlete)
            tryCompare(dialog, "opened", true)
            const name = findChild(dialog.contentItem, "nameField")
            tryCompare(name, "activeFocus", true)
            keyClick("j"); keyClick("u"); keyClick("g"); keyClick("e"); keyClick("n"); keyClick("d")
            const list = findChild(name, "suggestions")
            tryVerify(() => list && list.visible && list.count >= 3)
            // The DM Jugend is a DM
            const i = list.model.findIndex(t => t.text.indexOf("DM Jugend") === 0)
            verify(i >= 0)
            for (let k = 0; k <= i; ++k)
                keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Return)
            verify(name.text.indexOf("DM Jugend") === 0)
            compare(dialog.opened, true)
            const norm = findChild(dialog.contentItem, "normNote")
            tryVerify(() => norm.text.indexOf("Norm DM Jugend -89 kg") === 0)
            dialog.close()
        }
    }
}
