import QtQuick
import QtTest
import Trainingsplaner

// The Trainingsmittelkatalog 2018 as caps in RO and ITP: a BW above the
// value for the age, or an exercise or complex not meant for it yet,
// carries a warning; the competition itself does not
TestCase {
    name: "Tmk"

    ItpModel { id: grid }

    readonly property int warningRole: Qt.UserRole + 5
    readonly property int editRole: Qt.UserRole + 1
    property string mazId
    property var athletes: []

    function warning(r, c) { return grid.data(grid.index(r, c), warningRole) }
    function edit(r, c, v) { verify(grid.setData(grid.index(r, c), v, editRole)) }

    function initTestCase() {
        const r = Plan.saveMaz({ name: "TMK", sex: 0, from: "10/2032", to: "22/2032", template: "U17" })
        compare(r.error, "")
        mazId = r.id
        grid.owner = Plan.roOwner(mazId)
        grid.mazId = mazId
        grid.fromMonday = Plan.maz(mazId).fromMonday
        grid.weeks = 13
        // Reißen (WH, MHG, BW 0-2), Lastheben breit (3-5), K4 (6), K3 (7),
        // then K1-7, K1-5, Bel., WK (8-11)
        grid.exercises = [1, 15, -4, -3]
    }

    function cleanupTestCase() {
        grid.owner = ""
        Plan.removeMaz(mazId)
        for (const a of athletes)
            Store.removeAthlete(a)
    }

    function addAthlete(first, born) {
        const id = Store.saveAthlete({ lastName: "Katalog", firstName: first, sex: 0, born: born })
        athletes.push(id)
        Plan.saveMazAthlete({ mazId: mazId, athleteId: id, targetSnatch: 100, targetCleanJerk: 120 })
        grid.reload()
        return id
    }

    function test_1_ro() {
        // No athletes in the MAZ, no age: nothing to check
        edit(0, 2, "98")
        compare(warning(0, 2), "")

        // AK 16 in 2032: Jugend, Reißen up to 97 %
        addAthlete("Jule", "01.03.2016")
        compare(warning(0, 2), "Über dem TMK 2018 für Jugend (AK 16–17): BW bis 97 % des Wettkampfziels."
                               + " Die Jüngsten der MAZ sind Jugend (AK 16–17).")
        compare(warning(0, 1), "")
        edit(0, 2, "97")
        compare(warning(0, 2), "")
        // The RTK's own plan: K3 is for this age, the average row is not checked
        verify(Number(grid.data(grid.index(0, 7), Qt.DisplayRole)) > 0)
        compare(warning(0, 7), "")
        compare(warning(13, 2), "")

        // The main competition (HWK) goes to 100 %; without it, a warning
        compare(grid.data(grid.index(12, 11), Qt.DisplayRole), "HWK")
        compare(grid.data(grid.index(12, 2), Qt.DisplayRole), "100")
        compare(warning(12, 2), "")
        edit(12, 11, "")
        verify(warning(12, 2) !== "")
        edit(12, 11, "HWK")
        compare(warning(12, 2), "")

        // Lastheben and K4 only from the Junioren
        edit(1, 3, "10")
        compare(warning(1, 3), "Lastheben breit ist im TMK 2018 nicht für Jugend (AK 16–17) vorgesehen."
                               + " Die Jüngsten der MAZ sind Jugend (AK 16–17).")
        edit(1, 6, "20")
        verify(warning(1, 6).startsWith("K4 ist im TMK 2018 nicht für Jugend"))
        compare(warning(2, 6), "")

        // A younger one (AK 14, Schüler) sets the caps: 95 % with sets
        // of 2
        addAthlete("Sami", "01.03.2018")
        edit(0, 2, "96")
        compare(warning(0, 2), "Über dem TMK 2018 für Schüler (AK 14–15): BW bis 95 % des Wettkampfziels"
                               + " (95/2: BW/SG). Die Jüngsten der MAZ sind Schüler (AK 14–15).")
        edit(0, 2, "70")
        edit(1, 3, "")
        edit(1, 6, "")
    }

    function test_2_itp() {
        // The Jugend athlete's ITP in kg: 97 % of 100 kg
        const athlete = athletes[0]
        verify(Plan.itpFromRo(mazId, athlete))
        grid.owner = athlete
        compare(grid.data(grid.index(0, 2), Qt.DisplayRole), "70")
        compare(warning(0, 2), "")
        edit(0, 2, "97")
        compare(warning(0, 2), "")
        edit(0, 2, "98")
        compare(warning(0, 2), "Über dem TMK 2018 für Jugend (AK 16–17): BW bis 97 % des Wettkampfziels,"
                               + " 97 kg bei 100 kg Ziel.")
        // Their competition week: the target and more
        compare(warning(12, 2), "")
        // Born in 2014 the athlete is a Junior (AK 18): Lastheben is
        // allowed, 98 kg too
        edit(1, 3, "10")
        verify(warning(1, 3) !== "")
        Store.saveAthlete({ id: athlete, lastName: "Katalog", firstName: "Jule", sex: 0, born: "01.03.2014" })
        grid.reload()
        compare(warning(1, 3), "")
        compare(warning(0, 2), "")
        grid.owner = Plan.roOwner(mazId)
    }
}
