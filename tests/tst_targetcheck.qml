import QtQuick
import QtQuick.Controls
import QtTest
import Trainingsplaner
import TrainingsplanerStyle as Styles

// A MAZ target against the development curve of the athlete's yearly
// bests before the MAZ: a hint (never a block) and a proposal split as
// the athlete's lifts are
Item {
    width: 1366
    height: 860

    PlanningPage {
        id: planning
        anchors.fill: parent
        choosesAthlete: false
    }

    TestCase {
        name: "TargetCheck"
        when: windowShown

        property string athlete
        property string mazId
        readonly property var totals: [95, 128, 150, 158, 178, 184]

        function initTestCase() {
            athlete = Store.saveAthlete({ lastName: "Ziel", firstName: "Zora", sex: 1, born: "01.03.2004" })
            for (let i = 0; i < totals.length; ++i) {
                const s = Math.round(totals[i] * 0.45), j = totals[i] - s
                Store.saveCompetition({ athleteId: athlete, date: (2016 + i) + "-05-10", name: "LM", type: 0,
                                        bodyWeight: "60", snatch: [s, 0, 0], cleanJerk: [j, 0, 0] }, "", "")
            }
            // After the MAZ began: not known to its planning
            Store.saveCompetition({ athleteId: athlete, date: "2022-06-11", name: "Pokal", type: 0,
                                    bodyWeight: "60", snatch: [120, 0, 0], cleanJerk: [150, 0, 0] }, "", "")
            const r = Plan.saveMaz({ name: "Ziel-MAZ", sex: 1, from: "10/2022", to: "22/2022" })
            compare(r.error, "")
            mazId = r.id
            Plan.saveMazAthlete({ mazId: mazId, athleteId: athlete })
        }

        function cleanupTestCase() {
            Plan.removeMaz(mazId)
            Store.removeAthlete(athlete)
        }

        function test_1_check() {
            const none = Plan.targetCheck(mazId, athlete, 0, 0)
            verify(none.has)
            compare(none.year, 2022)
            // The curve for 2022 a little above 184, as in the competition chart
            verify(none.expected > 184 && none.expected < 200, none.expected)
            compare(none.verdict, "")
            // Split as the last year's best: 83 of 184
            const total = Math.round(none.expected)
            compare(none.proposedSnatch + none.proposedCleanJerk, total)
            compare(none.proposedSnatch, Math.round(total * 83 / 184))
            verify(none.text.indexOf("Nach der Entwicklungskurve (" + total + " kg für 2022): Vorschlag ") === 0)

            compare(Plan.targetCheck(mazId, athlete, none.proposedSnatch, none.proposedCleanJerk).verdict, "ok")
            const high = Plan.targetCheck(mazId, athlete, 100, 125)
            compare(high.verdict, "high")
            compare(high.text, "Zweikampf-Ziel 225 kg liegt " + Math.round(225 - none.expected)
                               + " kg über der Entwicklungskurve (" + total + " kg für 2022).")
            compare(Plan.targetCheck(mazId, athlete, 70, 90).verdict, "low")
            // Without four years before the MAZ: no curve, no hint
            const other = Store.saveAthlete({ lastName: "Ziel", firstName: "Neu", sex: 1 })
            compare(Plan.targetCheck(mazId, other, 80, 100).has, false)
            Store.removeAthlete(other)
        }

        function test_2_form() {
            planning.showTab("maz")
            const pane = findChild(planning, "mazPane")
            pane.select(mazId)
            // The rows the list replaced go first
            wait(50)
            tryVerify(() => findChild(pane, "targetHint") !== null && findChild(pane, "targetHint").visible)
            const hint = findChild(pane, "targetHint")
            verify(hint.text.indexOf("Vorschlag") > 0)
            const check = Plan.targetCheck(mazId, athlete, 0, 0)
            compare(findChild(pane, "targetSnatch").placeholderText, String(check.proposedSnatch))
            // Taken: saved as the athlete's targets, and it fits
            mouseClick(findChild(pane, "takeTarget"))
            const saved = Plan.mazAthletes(mazId).find(a => a.athleteId === athlete)
            compare([saved.targetSnatch, saved.targetCleanJerk], [check.proposedSnatch, check.proposedCleanJerk])
            tryVerify(() => hint.text.indexOf("passt zur Entwicklungskurve") > 0)
            // Too high: red, but saved all the same
            const ts = findChild(pane, "targetSnatch")
            ts.text = "120"
            ts.editingFinished()
            tryVerify(() => hint.text.indexOf("über der Entwicklungskurve") > 0)
            compare(hint.color, Styles.TokenInterface.semantics.danger_default)
            compare(Plan.mazAthletes(mazId).find(a => a.athleteId === athlete).targetSnatch, 120)
        }
    }
}
