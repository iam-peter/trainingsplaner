import QtQuick
import QtTest
import Trainingsplaner

// Pages show what was changed elsewhere: a competition entered in the
// month view is in the Wettkämpfe list, the Analyse chart is there when
// its tab opens
Item {
    id: window
    width: 1300
    height: 900

    CompetitionsPage {
        id: competitions
        anchors.fill: parent
        athleteId: "test_tina"
    }
    AnalysisPage {
        id: analysis
        anchors.fill: parent
        visible: false
        athleteId: "test_tina"
    }

    TestCase {
        name: "FollowData"
        when: windowShown

        function test_competitionFromElsewhere() {
            compare(Store.saveCompetitionDate("test_tina", "2031-05-05", 0, "Pokal", "", "", ""), "")
            tryVerify(() => competitions.list.some(c => c.date === "2031-05-05"))
            Store.removeCompetition("test_tina", "2031-05-05", "")
            tryVerify(() => !competitions.list.some(c => c.date === "2031-05-05"))
        }

        function test_chartWhenItsTabOpens() {
            competitions.visible = false
            analysis.visible = true
            findChild(analysis, "analysisTabs").currentIndex = 3
            const chart = findChild(analysis, "chartTab")
            tryVerify(() => chart.first.labels !== undefined && chart.first.labels.length === 12)
            analysis.visible = false
            competitions.visible = true
        }
    }
}
