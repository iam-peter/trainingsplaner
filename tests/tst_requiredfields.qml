import QtQuick
import QtTest
import Trainingsplaner

// Required fields say what is missing at the field itself: the MAZ form
// under the row of the field, the athlete form under the name
Item {
    width: 1366
    height: 860

    PlanningPage {
        id: planning
        anchors.fill: parent
        choosesAthlete: false
    }
    AthletesPage {
        id: athletes
        anchors.fill: parent
        visible: false
    }

    TestCase {
        name: "RequiredFields"
        when: windowShown

        function test_maz() {
            planning.showTab("maz")
            const pane = findChild(planning, "mazPane")
            pane.select("")
            const count = Plan.mazList.length
            // Nothing typed: the name, red, with the message under its row
            pane.save()
            compare(pane.errorField, "name")
            verify(findChild(pane, "mazName").error)
            const nameError = findChild(pane, "nameError")
            verify(nameError.visible)
            compare(nameError.text, "Bitte eine Bezeichnung eingeben.")
            // Typing in it puts it right
            const name = findChild(pane, "mazName")
            name.text = "Pflicht"
            name.textEdited()
            verify(!nameError.visible)
            verify(!name.error)
            // Then the weeks
            pane.save()
            compare(pane.errorField, "from")
            verify(findChild(pane, "weeksError").visible)
            findChild(pane, "mazFrom").text = "10/2040"
            findChild(pane, "mazFrom").textEdited()
            pane.save()
            compare(pane.errorField, "to")
            compare(findChild(pane, "weeksError").text, "Bitte die letzte Woche angeben, z.B. 22/2027.")
            findChild(pane, "mazTo").text = "22/2040"
            // A phase typed but no week: said, not dropped
            findChild(pane, "mazBuildUp").text = "Woche 16"
            pane.save()
            compare(pane.errorField, "buildUp")
            verify(findChild(pane, "phaseError").visible)
            verify(findChild(pane, "mazBuildUp").error)
            compare(Plan.mazList.length, count)
            findChild(pane, "mazBuildUp").text = "16/2040"
            pane.save()
            compare(pane.error, "")
            compare(Plan.mazList.length, count + 1)
            Plan.removeMaz(pane.mazId)
        }

        function test_athlete() {
            planning.visible = false
            athletes.visible = true
            athletes.select("")
            const before = Store.athletes.length
            const save = findChild(athletes, "saveAthlete")
            // The button works without a name, and says what is missing
            verify(save.enabled)
            mouseClick(save)
            verify(athletes.nameMissing)
            verify(findChild(athletes, "nameMissing").visible)
            verify(findChild(athletes, "lastNameField").error)
            compare(Store.athletes.length, before)
            const name = findChild(athletes, "lastNameField")
            name.text = "Pflicht"
            name.textEdited()
            verify(!findChild(athletes, "nameMissing").visible)
            athletes.visible = false
            planning.visible = true
        }
    }
}
