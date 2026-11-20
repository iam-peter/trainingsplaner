import QtQuick
import QtTest
import Trainingsplaner

// The DGJ's youth rules where competitions are: the DM Nachwuchs norm of
// the athlete's class (AK 16-17) or body weight (AK 14-15), one competition per week up to AK 17, the youth
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
            compare(s.weightClass, "-95")
            verify(s.dm.applies)
            compare(s.dm.norm, 198)
            compare(s.dm.best, 150)
            verify(!s.dm.reached)
            verify(s.dm.text.indexOf("Norm DM Nachwuchs -95 kg: 198 kg") === 0)
            verify(s.dm.text.indexOf("noch 48 kg") > 0)
            // Before this year's first competition there is none yet
            verify(Store.youthStatus(athlete, year + "-02-01").dm.text.indexOf("noch kein Zweikampf") > 0)
        }

        function test_editedNorm() {
            const norms = Store.dmNorms.map(n => n.sex === 0 && n.ageClass === 16 && n.weightClass === "-95"
                                            ? { sex: 0, ageClass: 16, weightClass: "-95", total: 150 } : n)
            Store.dmNorms = norms
            const s = Store.youthStatus(athlete, year + "-04-01")
            verify(s.dm.reached)
            verify(s.dm.text.indexOf("erfüllt") > 0)
            Store.dmNorms = []
            compare(Store.youthStatus(athlete, year + "-04-01").dm.norm, 198)
        }

        // AK 14 and 15 lift in weight groups: their norm goes by the body
        // weight, up to the next whole kg
        function test_normByBodyWeight() {
            const girl = Store.saveAthlete({ lastName: "Jugend", firstName: "Jana", sex: 1,
                                             born: "01.05." + (year - 15) })
            Store.saveCompetition({ athleteId: girl, date: year + "-03-07", name: "LM", bodyWeight: "45,3",
                                    snatch: [38, 0, 0], cleanJerk: [48, 0, 0] }, "", "")
            const s = Store.youthStatus(girl, year + "-04-01")
            compare(s.ageClass, 15)
            verify(s.dm.applies)
            compare(s.dm.norm, 83)
            verify(s.dm.text.indexOf("Norm DM Nachwuchs AK 15 bis 46 kg: 83 kg") === 0)
            // 38 + 48 kg
            compare(s.dm.best, 86)
            verify(s.dm.reached)
            // AK 13 has none
            const younger = Store.youthStatus(girl, (year - 2) + "-04-01")
            verify(!younger.dm.applies)
            compare(younger.dm.text, "")
            Store.removeCompetition(girl, year + "-03-07", "")
            Store.removeAthlete(girl)
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
            Store.saveCompetitionDate(athlete, d1, 1, "DM Nachwuchs (AK 14–17)", "Berlin", "", "")
            Store.saveCompetitionDate(athlete, d2, 0, "Pokal", "", "", "")
            const m = Store.month(athlete, (year + 1) + "-12-01", false)
            const dm = m.upcoming.find(c => c.date === d1)
            verify(dm.norm.indexOf("Norm DM Nachwuchs -95 kg: 198 kg") === 0)
            // Two in one week, at AK 17
            verify(dm.warning.indexOf("Zwei Wettkämpfe") === 0)
            Store.removeCompetition(athlete, d2, "")
            // Alone in its week: no warning (it is no conflict with itself)
            const alone = Store.month(athlete, (year + 1) + "-12-01", false).upcoming.find(c => c.date === d1)
            compare(alone.warning, "")
            compare(Store.weekConflict(athlete, d1, d1, ""), "")
            Store.removeCompetition(athlete, d1, "")
        }

        // Another competition on the same day counts too; only the one
        // being moved is left out
        function test_sameDayConflict() {
            const d = year + "-06-13"
            Store.saveCompetitionDate(athlete, d, 0, "Pokal", "", "", "")
            Store.saveCompetition({ athleteId: athlete, date: d, time: "18:00", name: "Liga", type: 0 }, "", "")
            verify(Store.weekConflict(athlete, d, d, "").indexOf("Liga") > 0)
            compare(Store.weekConflict(athlete, d, d, "18:00").indexOf("Pokal") > 0, true)
            Store.removeCompetition(athlete, d, "")
            Store.removeCompetition(athlete, d, "18:00")
        }

        function test_dialogOffersYouthCompetitions() {
            dialog.show(null, (year + 1) + "-03-10", athlete)
            tryCompare(dialog, "opened", true)
            const name = findChild(dialog.contentItem, "nameField")
            tryCompare(name, "activeFocus", true)
            keyClick("n"); keyClick("a"); keyClick("c"); keyClick("h"); keyClick("w")
            const list = findChild(name, "suggestions")
            tryVerify(() => list && list.visible && list.count >= 2)
            // The DM Nachwuchs is a DM
            const i = list.model.findIndex(t => t.text.indexOf("DM Nachwuchs") === 0)
            verify(i >= 0)
            for (let k = 0; k <= i; ++k)
                keyClick(Qt.Key_Down)
            keyClick(Qt.Key_Return)
            verify(name.text.indexOf("DM Nachwuchs") === 0)
            compare(dialog.opened, true)
            const norm = findChild(dialog.contentItem, "normNote")
            tryVerify(() => norm.text.indexOf("Norm DM Nachwuchs -95 kg") === 0)
            dialog.close()
        }
    }
}
